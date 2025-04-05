import 'package:expense_log/utility/helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpensePieChart extends StatelessWidget {
  final Map<String, double> expenseData;

  ExpensePieChart({required this.expenseData});

  final List<Color> _defaultColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
  ];

  @override
  Widget build(BuildContext context) {
    final sortedEntries = expenseData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final Map<String, double> displayData = {};
    double othersTotal = 0.0;

    for (int i = 0; i < sortedEntries.length; i++) {
      if (i < 7) {
        displayData[sortedEntries[i].key] = sortedEntries[i].value;
      } else {
        othersTotal += sortedEntries[i].value;
      }
    }

    if (othersTotal > 0) {
      displayData['Others'] = othersTotal;
    }

    final total = displayData.values.fold(0.0, (sum, item) => sum + item);
    final sections = <PieChartSectionData>[];

    int colorIndex = 0;

    displayData.forEach((label, value) {
      final percentage = total == 0 ? 0 : (value / total) * 100;

      sections.add(
        PieChartSectionData(
          color: _defaultColors[colorIndex % _defaultColors.length],
          value: value,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displayData.entries.mapIndexed((index, entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: _defaultColors[index % _defaultColors.length],
                ),
                SizedBox(width: 4),
                Text(
                  '${entry.key} (${entry.value.toStringAsFixed(2)})',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
