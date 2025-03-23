import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StaticLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LineChart(

          LineChartData(

            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    switch (value.toInt()) {
                      case 0:
                        return Text("Mon");
                      case 1:
                        return Text("Tue");
                      case 2:
                        return Text("Wed");
                      case 3:
                        return Text("Thu");
                      case 4:
                        return Text("Fri");
                      case 5:
                        return Text("Sat");
                      case 6:
                        return Text("Sun");
                      default:
                        return Text("");
                    }
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  FlSpot(0, 9), // Monday
                  FlSpot(1, 3), // Tuesday
                  FlSpot(2, 2.5), // Wednesday
                  FlSpot(3, 4), // Thursday
                  FlSpot(4, 3.5), // Friday
                  FlSpot(5, 5), // Saturday
                  FlSpot(6, 2), // Sunday
                ],
                isCurved: true, // Smooth curve
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(show: false),

              ),
            ],
          ),
        ),
      ),
    );
  }
}
