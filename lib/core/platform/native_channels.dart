import 'package:flutter/services.dart';

class NativeDeviceInfo {
  const NativeDeviceInfo({
    required this.modelName,
    required this.osVersion,
    required this.batteryPercent,
  });

  final String modelName;
  final String osVersion;
  final int batteryPercent;

  factory NativeDeviceInfo.fromMap(Map<Object?, Object?> map) {
    return NativeDeviceInfo(
      modelName: map['model'] as String? ?? 'Unknown',
      osVersion: map['osVersion'] as String? ?? 'Unknown',
      batteryPercent: (map['batteryPercent'] as num?)?.toInt() ?? -1,
    );
  }
}

enum NativeSheetOption { camera, gallery, filePicker }

class NativeChannelUnavailableException implements Exception {
  const NativeChannelUnavailableException(this.method, [this.detail]);

  final String method;
  final String? detail;

  @override
  String toString() =>
      'Native "$method" is unavailable on this platform${detail == null ? '' : ' ($detail)'}.';
}

class NativeChannels {
  const NativeChannels({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'com.smartworkspace.app/native';

  final MethodChannel _channel;

  Future<DateTime?> pickDate({DateTime? initialDate}) async {
    final picked = await _invoke<String?>('pickDate', {
      'initialDate': initialDate == null ? null : _isoDate(initialDate),
    });
    if (picked == null) return null;
    final parts = picked.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  Future<NativeSheetOption?> showNativeOptionsSheet() async {
    final choice = await _invoke<String?>('showNativeOptionsSheet');
    return switch (choice) {
      'camera' => NativeSheetOption.camera,
      'gallery' => NativeSheetOption.gallery,
      'file' => NativeSheetOption.filePicker,
      _ => null,
    };
  }

  Future<NativeDeviceInfo> getDeviceInfo() async {
    final info = await _invoke<Map<Object?, Object?>>('getDeviceInfo');
    return NativeDeviceInfo.fromMap(info ?? const {});
  }

  String _isoDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      throw NativeChannelUnavailableException(method);
    } on PlatformException catch (e) {
      throw NativeChannelUnavailableException(method, e.message ?? e.code);
    }
  }
}
