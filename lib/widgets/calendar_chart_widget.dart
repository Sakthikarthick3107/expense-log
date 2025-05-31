import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarChartWidget extends StatelessWidget {
  final Map<DateTime, double> dayAmountMap;
  final String durationType;
  final DateTimeRange? customDateRange;

  CalendarChartWidget({
    required this.dayAmountMap,
    required this.durationType,
    this.customDateRange,
  });

  DateTimeRange? _getDateRange(String rangeType, {DateTimeRange? customRange}) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    final type = rangeType.toLowerCase();

    switch (type) {
      case 'this week':
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday % 7));
        endDate = startDate.add(Duration(days: 6));
        break;
      case 'last week':
        startDate = now.subtract(Duration(days: (now.weekday + 7) % 7 + 7));
        endDate = startDate.add(Duration(days: 6));
        break;
      case 'this month':
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'last month':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0);
        break;
      case 'custom':
        if (customRange != null) {
          startDate = customRange.start;
          endDate = customRange.end;
        } else {
          return null;
        }
        break;
      default:
        return null;
    }

    // Normalize times to full days
    startDate = DateTime(startDate.year, startDate.month, startDate.day);
    endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return DateTimeRange(start: startDate, end: endDate);
  }

  Color _getColorForValue(double value, double max, BuildContext context) {
    if (value == 0) return Theme.of(context).scaffoldBackgroundColor;

    final normalized = (value / max).clamp(0.0, 1.0);

    if (normalized <= 0.25) {
      // Light Green 200 to Green 400
      return Color.lerp(
        Colors.lightGreen[200],
        Colors.green[400],
        normalized / 0.25,
      )!;
    } else if (normalized <= 0.5) {
      // Green 400 to Orange 400
      return Color.lerp(
        Colors.green[400],
        Colors.orange[400],
        (normalized - 0.25) / 0.25,
      )!;
    } else if (normalized <= 0.75) {
      // Orange 400 to Orange 700 (darker orange)
      return Color.lerp(
        Colors.orange[400],
        Colors.orange[700],
        (normalized - 0.5) / 0.25,
      )!;
    } else {
      // Orange 700 to Red 700
      return Color.lerp(
        Colors.orange[700],
        Colors.red[700],
        (normalized - 0.75) / 0.25,
      )!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = _getDateRange(durationType, customRange: customDateRange);

    if (dateRange == null) {
      return Center(child: Text('Invalid date range'));
    }

    final maxAmount = dayAmountMap.values.isEmpty
        ? 1.0
        : dayAmountMap.values.reduce((a, b) => a > b ? a : b);

    final today = DateTime.now();
    DateTime focusedDay;

    if (today.isBefore(dateRange.start)) {
      focusedDay = dateRange.start;
    } else if (today.isAfter(dateRange.end)) {
      focusedDay = dateRange.end;
    } else {
      focusedDay = today;
    }

    return TableCalendar(
      rowHeight: 35,
      firstDay: dateRange.start,
      lastDay: dateRange.end,
      focusedDay: focusedDay,
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, _) {
          final date = DateTime(day.year, day.month, day.day);

          if (date.isBefore(dateRange.start) || date.isAfter(dateRange.end)) {
            return SizedBox.shrink();
          }

          final amount = dayAmountMap[date] ?? 0.0;
          final color = _getColorForValue(amount, maxAmount, context);

          return Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8.0),
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: amount > 0
                    ? Colors.white
                    : Theme.of(context).textTheme.displayMedium!.color,
                fontWeight: FontWeight.normal,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
      calendarStyle: CalendarStyle(
        isTodayHighlighted: false,
        outsideDaysVisible: false,
      ),
      calendarFormat: CalendarFormat.month,
      daysOfWeekVisible: true,
    );
  }
}
