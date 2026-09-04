import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const int dailyReminderId = 0;
  static const String _channelId = 'smart_workspace_reminders';
  static const String _channelName = 'Reminders';

  // Guards every method below so a platform with no notification channel
  // (desktop dev builds, widget tests) degrades to a silent no-op instead of
  // throwing a MissingPluginException out of app startup.
  bool _available = false;

  Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      _available = true;
    } catch (_) {
      _available = false;
    }
  }

  // Every method below is fired automatically (app start, a note save, a
  // timer completing) with no user gesture attached to react to a failure,
  // so — same call as init() above — a plugin error here is swallowed
  // rather than thrown: there's no sensible UI to surface it on, and the
  // caller (e.g. a repository save) shouldn't fail just because a
  // best-effort reminder couldn't be scheduled.
  Future<void> scheduleDailyReminder({int hour = 9, int minute = 0}) async {
    if (!_available) return;
    try {
      await _plugin.zonedSchedule(
        id: dailyReminderId,
        title: 'Smart Workspace',
        body: 'Check your notes and tasks for today.',
        scheduledDate: _nextInstanceOf(hour, minute),
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Best-effort — see method doc comment.
    }
  }

  Future<void> cancelDailyReminder() async {
    if (!_available) return;
    try {
      await _plugin.cancel(id: dailyReminderId);
    } catch (_) {
      // Best-effort — see method doc comment.
    }
  }

  Future<void> scheduleNoteReminder({
    required String noteId,
    required String noteTitle,
    required DateTime date,
    int hour = 9,
  }) async {
    if (!_available) return;
    final scheduled = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
    );
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    try {
      await _plugin.zonedSchedule(
        id: _idForNote(noteId),
        title: 'Reminder: ${noteTitle.isEmpty ? 'Untitled note' : noteTitle}',
        body: 'This note is due today.',
        scheduledDate: scheduled,
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Best-effort — see method doc comment.
    }
  }

  Future<void> cancelNoteReminder(String noteId) async {
    if (!_available) return;
    try {
      await _plugin.cancel(id: _idForNote(noteId));
    } catch (_) {
      // Best-effort — see method doc comment.
    }
  }

  Future<void> showProgress({
    required String title,
    required String body,
  }) async {
    if (!_available) return;
    try {
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        title: title,
        body: body,
        notificationDetails: _details(),
      );
    } catch (_) {
      // Best-effort — see method doc comment.
    }
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(_channelId, _channelName),
      iOS: DarwinNotificationDetails(),
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // Jenkins one-at-a-time hash — deterministic across app runs, unlike
  // Dart's String.hashCode, so the same note id always cancels the exact
  // notification it scheduled.
  int _idForNote(String noteId) {
    var hash = 0;
    for (final unit in noteId.codeUnits) {
      hash = 0x1fffffff & (hash + unit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash + 1;
  }
}
