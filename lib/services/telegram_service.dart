import 'dart:convert';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:http/http.dart' as http;

class TelegramService {
  static const String botToken =
      '7537294380:AAEIG0hD_WxzWOBldPRgnGUXuHDZfGz98NA'; // Replace with your bot token
  static const String apiUrl = 'https://api.telegram.org/bot$botToken';

  static Future<void> checkForUpdates() async {
    final url = Uri.parse('$apiUrl/getUpdates');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      for (final update in data['result']) {
        final message = update['message'];
        if (message == null) continue;

        final chatId = message['chat']['id'].toString();
        final text = message['text']?.trim();

        if (text != null) {
          await handleCommand(chatId, text);
        }
      }

      // Optional: Clear handled updates
      final updateIds = data['result'].map((e) => e['update_id']).toList();
      if (updateIds.isNotEmpty) {
        final lastId = updateIds.last;
        final clearUrl = Uri.parse(
          '$apiUrl/getUpdates?offset=${lastId + 1}',
        );
        await http.get(clearUrl);
      }
    } else {
      throw Exception('Failed to fetch updates: ${response.body}');
    }
  }

  static Future<void> handleCommand(String chatId, String command) async {
    UiService uiService = UiService();
    ExpenseService expenseService = ExpenseService(uiService: uiService);
    switch (command.trim()) {
      case '1':
        List<Expense2> todayExp =
            expenseService.getExpensesOfTheDay(DateTime.now());
        String expenseFrame = todayExp.isEmpty
            ? 'No Expense recorded for today'
            : 'Today\'s expense is : \n ${todayExp.map((e) => '${e.name} - ₹${e.price}').join('\n')}';
        await sendMessage(chatId, expenseFrame);
        break;
      // case '2':
      //   // Replace with your report logic
      //   await sendMessage(chatId,
      //       '📊 Today\'s report:\n- Food: ₹500\n- Travel: ₹300\n- Others: ₹434');
      //   break;
      case '2':
      default:
        await sendMessage(
            chatId,
            '🤖 Available commands:\n'
            '1 - Show Today\'s Expense\n'
            // '2 - Show Today\'s Report\n'
            '2 - Show this menu');
        break;
    }
  }

  static Future<void> sendMessage(String chatId, String message) async {
    final url = Uri.parse('$apiUrl/sendMessage');

    final response = await http.post(url, body: {
      'chat_id': chatId,
      'text': message,
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }
}
