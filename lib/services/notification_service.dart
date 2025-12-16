import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Timezone initialization for scheduled notifications
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(settings);

    _initialized = true;
    await requestPermission();
    await _ensureDefaultChannel();
  }

  Future<void> requestPermission() async {
    // Android 13+ runtime permission; iOS permissions handled by plugin
    await Permission.notification.request();
  }

  Future<void> _ensureDefaultChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'general',
      'General Notifications',
      description: 'General updates and reminders',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showNow({
    required String title,
    required String body,
    String channelId = 'general',
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'General Notifications',
        channelDescription: 'General updates and reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
  }

  Future<int> scheduleAt({
    required DateTime when,
    required String title,
    required String body,
    String channelId = 'general',
  }) async {
    final id = when.millisecondsSinceEpoch ~/ 1000;
    final tzTime = tz.TZDateTime.from(when, tz.local);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'General Notifications',
        channelDescription: 'General updates and reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
    return id;
  }
}


