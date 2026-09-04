import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps `connectivity_plus` behind a simple online/offline stream, plus a
/// debug-only manual override so offline mode can be demoed without
/// actually pulling the network cable.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  final Connectivity _connectivity;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _actualOnline = true;
  bool? _manualOverride;

  Stream<bool> get onlineStream => _controller.stream;

  bool get isOnline => _manualOverride ?? _actualOnline;

  Future<void> _init() async {
    try {
      final initial = await _connectivity.checkConnectivity();
      _actualOnline = _isOnlineResult(initial);
      _emit();
      _subscription = _connectivity.onConnectivityChanged.listen(
        (results) {
          _actualOnline = _isOnlineResult(results);
          _emit();
        },
        onError: (_) {},
      );
    } catch (_) {
      // Connectivity plugin unavailable (e.g. a plain `flutter test`
      // harness with no platform bindings) — default to online.
      _actualOnline = true;
      _emit();
    }
  }

  bool _isOnlineResult(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  /// Pass `true`/`false` to force that state regardless of the real signal,
  /// or `null` to go back to following the real signal. Debug-only — wired
  /// to a toggle in the app bar so offline mode can be demoed reliably.
  void setManualOverride(bool? isOnline) {
    _manualOverride = isOnline;
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(isOnline);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
