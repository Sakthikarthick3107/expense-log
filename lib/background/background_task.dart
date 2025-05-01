import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:workmanager/workmanager.dart';
import '../services/notification_service.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'expense_log_bg',
        'Expense Log Background Task',
        channelDescription: 'Background triggered check',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      final List<String> messages = [
        "Don't forget to track your daily expenses buddy 😉",
        "Stay on top of your budget! 💰",
        "Logging your expenses now helps future you. 📘",
        "How much did you spend this hour? 🕒",
        "Small expenses add up! Keep an eye. 👀",
      ];
      int hour = DateTime.now().hour;
      String dynamicMessage = messages[hour % messages.length];

      switch (taskName) {
        case "dailyExpenseSummary":
          print("Executing dailyExpenseSummary task...");
          await NotificationService.notificationsPlugin.show(
            1,
            'Reminder',
            dynamicMessage,
            // 'hello',
            platformDetails,
          );

          break;
        case "fetchLatest":
          final String owner = 'Sakthikarthick3107';
          final String repo = 'expense-log';
          final url = Uri.parse(
              'https://api.github.com/repos/$owner/$repo/releases/latest');
          final packageInfo = await PackageInfo.fromPlatform();
          final currentVersion = packageInfo.version;

          final response = await http.get(url);
          if (response.statusCode == 200) {
            final jsonData = jsonDecode(response.body);
            final latestVersion = jsonData['tag_name'];
            if (isNewVersion(latestVersion, currentVersion)) {
              await NotificationService.notificationsPlugin.show(
                999,
                'Update now for an improved experience',
                'A new update is ready. Tap to update now!',
                // 'hello',
                platformDetails,
              );
            }
          }
        default:
          print("Unknown background task: $taskName");
          break;
      }
      return Future.value(true);
    } catch (e, stack) {
      print("❌ Error in background task: $e");
      print("🪵 StackTrace: $stack");
      return Future.value(false); // Must return false on failure
    }
  });
}

bool isNewVersion(String latest, String current) {
  latest = latest.replaceFirst('v', '');
  current = current.replaceFirst('v', '');

  bool isLatestSemantic = latest.contains('.');
  bool isCurrentSemantic = current.contains('.');

  if (!isLatestSemantic && !isCurrentSemantic) {
    int latestBuild = int.parse(latest);
    int currentBuild = int.parse(current);
    return latestBuild > currentBuild;
  }

  if (isLatestSemantic && !isCurrentSemantic) {
    return true;
  }

  if (!isLatestSemantic && isCurrentSemantic) {
    return false;
  }

  List<int> latestParts = _parseVersion(latest);
  List<int> currentParts = _parseVersion(current);

  for (int i = 0; i < latestParts.length; i++) {
    int latestPart = latestParts[i];
    int currentPart = i < currentParts.length ? currentParts[i] : 0;
    if (latestPart > currentPart) {
      return true;
    } else if (latestPart < currentPart) {
      return false;
    }
  }
  return false;
}

List<int> _parseVersion(String version) {
  return version.split(RegExp(r'[.+]')).map(int.parse).toList();
}
