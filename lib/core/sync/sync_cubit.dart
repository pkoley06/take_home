import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../network/connectivity_service.dart';
import 'sync_queue.dart';

class SyncState extends Equatable {
  const SyncState({
    this.isOnline = true,
    this.pendingCount = 0,
    this.isSyncing = false,
    this.isManualOverride = false,
    this.justSyncedAt,
  });

  final bool isOnline;
  final int pendingCount;
  final bool isSyncing;
  final bool isManualOverride;
  final DateTime? justSyncedAt;

  SyncState copyWith({
    bool? isOnline,
    int? pendingCount,
    bool? isSyncing,
    bool? isManualOverride,
    DateTime? justSyncedAt,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      pendingCount: pendingCount ?? this.pendingCount,
      isSyncing: isSyncing ?? this.isSyncing,
      isManualOverride: isManualOverride ?? this.isManualOverride,
      justSyncedAt: justSyncedAt,
    );
  }

  @override
  List<Object?> get props =>
      [isOnline, pendingCount, isSyncing, isManualOverride, justSyncedAt];
}

/// Watches connectivity + the offline write queue and drains the queue
/// (with a short simulated delay per item) whenever it's online and the
/// queue isn't empty — on reconnect, or right after a new write is queued.
class SyncCubit extends Cubit<SyncState> {
  SyncCubit(this._connectivity, this._queue) : super(const SyncState());

  final ConnectivityService _connectivity;
  final SyncQueue _queue;

  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<void>? _queueSub;
  bool _draining = false;

  Future<void> init() async {
    try {
      final online = _connectivity.isOnline;
      final pendingCount = await _queue.count();
      emit(state.copyWith(isOnline: online, pendingCount: pendingCount));

      _connectivitySub = _connectivity.onlineStream.listen((online) {
        emit(state.copyWith(isOnline: online));
        if (online) _drainQueue();
      });

      _queueSub = _queue.onChanged.listen((_) async {
        emit(state.copyWith(pendingCount: await _queue.count()));
        if (state.isOnline) _drainQueue();
      });

      if (online && pendingCount > 0) _drainQueue();
    } catch (_) {
      // Connectivity plugin unavailable (e.g. a plain `flutter test`
      // harness) — keep the default online/empty-queue state.
    }
  }

  /// Debug-only: forces connectivity to the opposite of whatever is
  /// currently showing, regardless of the device's real signal — so
  /// offline mode can be demoed reliably even if the emulator's real
  /// connectivity happens to already be offline (or online).
  void toggleDebugOffline() {
    final forcedOnline = !state.isOnline;
    _connectivity.setManualOverride(forcedOnline);
    emit(state.copyWith(isOnline: forcedOnline, isManualOverride: true));
  }

  Future<void> _drainQueue() async {
    if (_draining) return;
    _draining = true;
    emit(state.copyWith(isSyncing: true));

    var syncedAny = false;
    try {
      while (state.isOnline) {
        final entries = await _queue.getAll();
        if (entries.isEmpty) break;

        await Future.delayed(const Duration(milliseconds: 500));
        if (!state.isOnline) break;

        await _queue.remove(entries.first.id);
        syncedAny = true;
        emit(state.copyWith(pendingCount: await _queue.count()));
      }
    } finally {
      _draining = false;
      final syncedAt = syncedAny ? DateTime.now() : null;
      emit(state.copyWith(isSyncing: false, justSyncedAt: syncedAt));
      if (syncedAt != null) {
        Timer(const Duration(seconds: 2), () {
          if (!isClosed && state.justSyncedAt == syncedAt) {
            emit(state.copyWith());
          }
        });
      }
    }
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    _queueSub?.cancel();
    return super.close();
  }
}
