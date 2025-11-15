import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:path/path.dart' as p;
import 'package:open_file/open_file.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize the notification plugin
  static Future<void> initialize() async {
    await _requestNotificationPermission();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid, iOS: iosSettings);

    await notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onSelectNotification);
  }

  // Request notification permission for Android
  static Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.notification.status;

      if (!status.isGranted) {
        // Permission not granted, request it
        PermissionStatus permissionStatus =
            await Permission.notification.request();

        if (permissionStatus.isGranted) {
          print("Notification permission granted");
        } else {
          print("Notification permission denied");
        }
      } else {
        print("Notification permission already granted");
      }
    }
  }

  // Schedule a notification at a specific time
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'expense_log_notifications', // Channel ID
      'Daily Expense Notifications', // Channel Name
      channelDescription: 'Notifications for time of the day of Expense Log',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _scheduleDailyTime(hour, minute),
      platformChannelSpecifics,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static tz.TZDateTime _scheduleDailyTime(int hour, int minute) {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    return scheduledDate.isBefore(now)
        ? scheduledDate.add(const Duration(days: 1))
        : scheduledDate;
  }

  static Future<void> onSelectNotification(
      NotificationResponse notificationResponse) async {
    print('Notification tapped with payload: ${notificationResponse.payload}');
    if (notificationResponse.payload != null) {
      final filePath = notificationResponse.payload;
      final file = File(filePath!);
      if (await file.exists()) {
        await OpenFile.open(file.path);
      } else {
        print('File does not exist');
      }
    }
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'instant_channel',
      'Instant Notifications',
      channelDescription: 'Notifications shown immediately',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ticker: 'ticker',
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  static Future<void> showDownloadCompletedNotification(File file) async {
    String fileName = p.basename(file.path);
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'download_channel',
      'Download Notifications',
      channelDescription: 'Notification when download completes',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await notificationsPlugin.show(
      100,
      'Download Complete',
      '${fileName}',
      notificationDetails,
      payload: file.path,
    );
  }
}
