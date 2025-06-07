import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';

// Top-level callback function (required by Alarm Manager)
Future<void> alarmCallback() async {
  final appDir = await getApplicationDocumentsDirectory();
  Hive.init(appDir.path);

  Hive.registerAdapter(Expense2Adapter());
  Hive.registerAdapter(ExpenseTypeAdapter());

  var expenseBox = await Hive.openBox<Expense2>('expense2Box');
  var settingsBox = await Hive.openBox('settingsBox');

  var expenseId = settingsBox.get('expenseId', defaultValue: 1) as int;

  final newExpense = Expense2(
    id: expenseId,
    name: 'Scheduled entry',
    price: 90,
    expenseType: ExpenseType(id: 2, name: 'food'),
    date: DateTime.now(),
    created: DateTime.now(),
  );

  await expenseBox.put(expenseId, newExpense);
  await settingsBox.put('expenseId', ++expenseId);

  print('Alarm callback: Entry added $newExpense');
}

class AlarmSchedule {
  void scheduleExact10AM() async {
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, 9, 55);
    DateTime alarmTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(Duration(days: 1))
        : scheduledTime;

    final int alarmId = 123;
    await AndroidAlarmManager.oneShotAt(
      alarmTime,
      alarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
    );

    print('Alarm scheduled for: $alarmTime');
  }
}
