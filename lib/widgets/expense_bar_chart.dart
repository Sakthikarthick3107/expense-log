import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpenseBarChart extends StatelessWidget {
  final Map<String, double> expenseData; // Expense types with values

  ExpenseBarChart({required this.expenseData});

  double getDynamicInterval(Map<String, double> data) {
    double maxY = data.values.isNotEmpty ? data.values.reduce((a, b) => a > b ? a : b) : 1;
    return (maxY / 5).ceilToDouble();
  }


  @override
  Widget build(BuildContext context) {
    double maxYValue = expenseData.values.isNotEmpty ? expenseData.values.reduce((a, b) => a > b ? a : b) : 10;
    double interval = (maxYValue / 5).ceilToDouble();

    List<BarChartGroupData> barGroups = [];
    List<String> expenseTypes = expenseData.keys.toList();

    for (int i = 0; i < expenseTypes.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: expenseData[expenseTypes[i]]!,
              color: Theme.of(context).colorScheme.primary,
              width: 18,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: expenseData.length * 60,
        child: BarChart(
      
          BarChartData(
            maxY: maxYValue + interval,
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false, border: Border.all(color: Colors.black)),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  getTitlesWidget: (value, meta) {
                    return Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10),

                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < expenseTypes.length) {
                      return Transform.rotate(
                        angle: -0.2,
                        child: Text(
                          expenseTypes[index],
                          style: TextStyle(fontSize: 12),
                        ),
                      );
                    }
                    return Container();
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide right Y-axis
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide top X-axis
            ),
            barGroups: barGroups,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group,groupIndex,rod,rodIndex){
                  return BarTooltipItem( '${rod.toY.toStringAsFixed(2)}',
                     TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),

                  );
                }
              )
            )
          ),
        ),
      ),
    );
  }
}
