import 'package:expense_log/models/schedule.dart';

class ScheduleUtils {
  static DateTime? findNextTriggerTime(Schedule schedule, DateTime fromTime) {
    DateTime now = fromTime;
    DateTime baseTime =
        DateTime(now.year, now.month, now.day, schedule.hour, schedule.minute);

    int mapToCustomWeekday(int dartWeekday) {
      return dartWeekday % 7;
    }

    if (schedule.repeatOption == RepeatOption.CustomDays &&
        schedule.customByType == CustomByType.Month) {
      // Month logic
      for (int i = 0; i <= 12; i++) {
        int targetMonth = (now.month + i - 1) % 12 + 1;
        int targetYear = now.year + ((now.month + i - 1) ~/ 12);

        for (var targetDay in schedule.customDays!) {
          if (targetDay < 1 || targetDay > 31) continue;
          DateTime potentialTime = DateTime(targetYear, targetMonth, targetDay,
              schedule.hour, schedule.minute);
          if (potentialTime.isAfter(now)) {
            return potentialTime;
          }
        }
      }
      return null;
    } else {
      // Week-based or simple day logic
      int daysToAdd = 0;
      while (daysToAdd <= 31) {
        DateTime potentialTime = baseTime.add(Duration(days: daysToAdd));
        int weekday = mapToCustomWeekday(potentialTime.weekday);

        bool found = false;
        switch (schedule.repeatOption) {
          case RepeatOption.Once:
            found = daysToAdd == 0 && potentialTime.isAfter(now);
            break;
          case RepeatOption.Everyday:
            found = potentialTime.isAfter(now);
            break;
          case RepeatOption.Weekdays:
            found =
                (weekday >= 1 && weekday <= 5) && potentialTime.isAfter(now);
            break;
          case RepeatOption.Weekends:
            found =
                (weekday == 0 || weekday == 6) && potentialTime.isAfter(now);
            break;
          case RepeatOption.CustomDays:
            if (schedule.customDays != null &&
                schedule.customByType == CustomByType.Week) {
              found = schedule.customDays!.contains(weekday) &&
                  potentialTime.isAfter(now);
            }
            break;
        }

        if (found) {
          return potentialTime;
        }

        daysToAdd++;
      }
      return null;
    }
  }
}
