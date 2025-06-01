import 'package:expense_log/models/expense2.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum GroupBy { Week, Month }

class TypeUsageChart extends StatefulWidget {
  final List<Expense2> expenses;
  final GroupBy groupBy;

  const TypeUsageChart(
      {super.key, required this.expenses, this.groupBy = GroupBy.Month});

  @override
  State<TypeUsageChart> createState() => _TypeUsageChartState();
}

class _TypeUsageChartState extends State<TypeUsageChart> {
  List<FlSpot> _spots = [];
  List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _generateChartData();
  }

  void _generateChartData() {
    final Map<DateTime, double> groupedData = {};

    if (widget.groupBy == GroupBy.Month) {
      for (var expense in widget.expenses) {
        final monthStart = DateTime(expense.date.year, expense.date.month);
        groupedData.update(
          monthStart,
          (value) => value + expense.price,
          ifAbsent: () => expense.price,
        );
      }
    } else {
      for (var expense in widget.expenses) {
        final weekStart =
            expense.date.subtract(Duration(days: expense.date.weekday - 1));
        final weekStartDate =
            DateTime(weekStart.year, weekStart.month, weekStart.day);
        groupedData.update(
          weekStartDate,
          (value) => value + expense.price,
          ifAbsent: () => expense.price,
        );
      }
    }

    // Sort by DateTime keys
    final sortedEntries = groupedData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    _spots = [];
    _labels = [];

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      _spots.add(FlSpot(i.toDouble(), entry.value));

      if (widget.groupBy == GroupBy.Month) {
        _labels.add(DateFormat('MMM yyyy').format(entry.key));
      } else {
        final weekLabel = 'Week ${weekNumber(entry.key)}\n${entry.key.year}';
        _labels.add(weekLabel);
      }
    }
  }

  int weekNumber(DateTime date) {
    final beginningOfYear = DateTime(date.year, 1, 1);
    final daysPassed = date.difference(beginningOfYear).inDays;
    return ((daysPassed + beginningOfYear.weekday) / 7).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return _spots.isEmpty
        ? const Center(child: Text("No data to display"))
        : SizedBox(
            height: 250,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (_spots.length - 1).toDouble(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          String formatted;
                          if (value >= 1000000) {
                            formatted =
                                (value / 1000000).toStringAsFixed(1) + 'M';
                          } else if (value >= 1000) {
                            formatted = (value / 1000).toStringAsFixed(1) + 'k';
                          } else {
                            formatted = value.toStringAsFixed(0);
                          }

                          return Text(
                            formatted,
                            style: const TextStyle(fontSize: 8),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _labels.length) {
                            return Text(
                              _labels[index],
                              style: const TextStyle(fontSize: 8),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _spots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 2,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
