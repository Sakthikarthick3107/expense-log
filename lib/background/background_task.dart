import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import '../services/notification_service.dart';

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
