import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/models/schedule.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expense_log/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_log/utility/schedule_utils.dart';

class ScheduleService extends ChangeNotifier {
  final _scheduleBox = Hive.box<Schedule>('scheduleBox');

  List<Schedule> getSchedules() {
    return _scheduleBox.values.toList();
  }

  Future<void> createSchedule(Schedule schedule) async {
    await _scheduleBox.put(schedule.id, schedule);
    if (schedule.isActive) {
      await _registerAlarm(schedule);
    }
    notifyListeners();
  }

  Future<void> editSchedule(Schedule schedule) async {
    await _cancelAlarm(schedule.id);
    await Future.delayed(Duration(milliseconds: 100));

    await _scheduleBox.put(schedule.id, schedule);

    if (schedule.isActive) {
      await _registerAlarm(schedule);
    }
    notifyListeners();
  }

  Future<void> handleActivation(int scheduleId, bool isActivate) async {
    final schedule = _scheduleBox.get(scheduleId);
    if (schedule != null) {
      schedule.isActive = isActivate;
      await _scheduleBox.put(scheduleId, schedule);
      isActivate
          ? await _registerAlarm(schedule)
          : await _cancelAlarm(scheduleId);
    }
    notifyListeners();
  }

  Future<void> deleteSchedule(int scheduleId) async {
    await _cancelAlarm(scheduleId);
    await _scheduleBox.delete(scheduleId);
    notifyListeners();
  }

  Future<void> _registerAlarm(Schedule schedule) async {
    DateTime? nextTrigger =
        ScheduleUtils.findNextTriggerTime(schedule, DateTime.now());

    if (nextTrigger == null) {
      print('No valid day found for schedule id ${schedule.id}');
      return;
    }

    final _scheduleEditBox = Hive.box<Schedule>('scheduleBox');
    schedule.nextTriggerAt = nextTrigger;
    _scheduleEditBox.put(schedule.id, schedule);

    await AndroidAlarmManager.oneShotAt(
      nextTrigger,
      schedule.id,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    print('Alarm registered for schedule id ${schedule.id} at $nextTrigger');
  }

  Future<void> _cancelAlarm(int alarmId) async {
    await AndroidAlarmManager.cancel(alarmId);
    print('Alarm canceled for schedule id $alarmId');
  }
}

@pragma('vm:entry-point')
Future<void> alarmCallback(int alarmId) async {
  final appDir = await getApplicationDocumentsDirectory();
  Hive.init(appDir.path);

  if (!Hive.isAdapterRegistered(Expense2Adapter().typeId)) {
    Hive.registerAdapter(Expense2Adapter());
  }
  if (!Hive.isAdapterRegistered(ExpenseTypeAdapter().typeId)) {
    Hive.registerAdapter(ExpenseTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(ScheduleAdapter().typeId)) {
    Hive.registerAdapter(ScheduleAdapter());
  }
  if (!Hive.isAdapterRegistered(ScheduleTypeAdapter().typeId)) {
    Hive.registerAdapter(ScheduleTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(RepeatOptionAdapter().typeId)) {
    Hive.registerAdapter(RepeatOptionAdapter());
  }
  if (!Hive.isAdapterRegistered(CustomByTypeAdapter().typeId)) {
    Hive.registerAdapter(CustomByTypeAdapter());
  }

  var scheduleBox = await Hive.openBox<Schedule>('scheduleBox');
  var expenseBox = await Hive.openBox<Expense2>('expense2Box');
  var settingsBox = await Hive.openBox('settingsBox');

  tz.initializeTimeZones();
  await NotificationService.initialize();

  final schedule = scheduleBox.get(alarmId);

  if (schedule != null) {
    final now = DateTime.now();

    // Safe duplicate check (if you add lastTriggeredTime field in model):
    /*
    if (schedule.lastTriggeredTime != null &&
        now.difference(schedule.lastTriggeredTime!).inMinutes < 1) {
      print('Skipping duplicate firing for schedule ${schedule.id}');
      return;
    }

    schedule.lastTriggeredTime = now;
    await scheduleBox.put(schedule.id, schedule);
    */

    // Main logic:
    var expenseId = settingsBox.get('expenseId', defaultValue: 1) as int;
    expenseId += 1;
    if (schedule.scheduleType == ScheduleType.AutoExpense &&
        schedule.data != null) {
      for (var expenseTemplate in schedule.data!) {
        final newExpense = Expense2(
          id: expenseId,
          name: expenseTemplate.name,
          price: expenseTemplate.price,
          expenseType: expenseTemplate.expenseType,
          date: DateTime.now(),
          created: DateTime.now(),
        );

        await expenseBox.put(expenseId, newExpense);
        print('Alarm callback: Entry added $newExpense');
        expenseId++;
      }
      await NotificationService.showInstantNotification(
          id: alarmId,
          title: 'Scheduled Expense Status',
          body: '${schedule.name} created successfully!');

      await settingsBox.put('expenseId', expenseId);
    }

    if (schedule.scheduleType == ScheduleType.Reminder) {
      await NotificationService.showInstantNotification(
          id: alarmId,
          title: 'Scheduled Reminder',
          body: '${schedule.name} ${schedule.description}');
    }

    // ---- Handle repeat ----
    if (schedule.repeatOption != RepeatOption.Once && schedule.isActive) {
      DateTime? nextScheduledTime =
          ScheduleUtils.findNextTriggerTime(schedule, DateTime.now());

      if (nextScheduledTime != null) {
        schedule.nextTriggerAt = nextScheduledTime;
        await scheduleBox.put(schedule.id, schedule);
        await AndroidAlarmManager.oneShotAt(
          nextScheduledTime,
          schedule.id,
          alarmCallback,
          exact: true,
          wakeup: true,
          allowWhileIdle: true,
          rescheduleOnReboot: true,
        );
      }
    }
  }

  int mapToCustomWeekday(int dartWeekday) {
    return dartWeekday % 7;
  }
}
