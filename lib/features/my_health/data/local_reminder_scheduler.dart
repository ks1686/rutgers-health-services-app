import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_plan.dart';
import 'reminder_scheduler.dart';

/// On-phone alerts for saved My Health records. Never contacts a server.
class LocalReminderScheduler extends SyncingReminderScheduler {
  LocalReminderScheduler() : super(_PluginNotificationPoster());
}

class _PluginNotificationPoster implements NotificationPoster {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  var _tzReady = false;

  static const _channelId = 'cwc_my_health_reminders';
  static const _channelName = 'My Health reminders';
  static const _channelDescription =
      'Medication and appointment reminders saved on this phone.';

  @override
  Future<void> init() async {
    await _configureLocalZone();
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwin,
        macOS: darwin,
      ),
    );
  }

  Future<void> _configureLocalZone() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    final mobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (mobile) {
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        // Keep the timezone database default if the device zone is unavailable.
      }
    }
    _tzReady = true;
  }

  @override
  Future<bool> requestPermission({bool precise = false}) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      if (precise) {
        try {
          final exact = await android.canScheduleExactNotifications();
          if (exact != true) {
            await android.requestExactAlarmsPermission();
          }
        } catch (_) {
          // Exact alarms are optional. Inexact alerts still fire on device.
        }
      }
      return granted ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          false;
    }
    final mac = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (mac != null) {
      return await mac.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  @override
  Future<bool> notificationsAllowed() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final options = await ios.checkPermissions();
      return options?.isEnabled ?? false;
    }
    final mac = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (mac != null) {
      final options = await mac.checkPermissions();
      return options?.isEnabled ?? false;
    }
    return false;
  }

  @override
  Future<List<ScheduledReminder>> pending() async {
    final pending = await _plugin.pendingNotificationRequests();
    return [
      for (final request in pending)
        ScheduledReminder(id: request.id, payload: request.payload),
    ];
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> schedule(ReminderRequest request) async {
    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
    final when = tz.TZDateTime.from(request.fireAt.toLocal(), tz.local);
    final mode = await _androidMode();
    try {
      await _schedule(request, when, details, mode);
    } catch (_) {
      if (mode == AndroidScheduleMode.inexactAllowWhileIdle) rethrow;
      await _schedule(
        request,
        when,
        details,
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _schedule(
    ReminderRequest request,
    tz.TZDateTime when,
    NotificationDetails details,
    AndroidScheduleMode mode,
  ) {
    return _plugin.zonedSchedule(
      id: request.id,
      title: request.title,
      body: request.body,
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: mode,
      payload: request.payload,
      matchDateTimeComponents: request.repeatsDaily
          ? DateTimeComponents.time
          : null,
    );
  }

  Future<AndroidScheduleMode> _androidMode() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;
    try {
      final exact = await android.canScheduleExactNotifications();
      if (exact ?? false) return AndroidScheduleMode.exactAllowWhileIdle;
    } catch (_) {
      // Fall through to inexact.
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }
}
