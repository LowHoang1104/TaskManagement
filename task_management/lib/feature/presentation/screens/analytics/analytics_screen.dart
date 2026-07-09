import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildChartCard(
              title: "Task Status Distribution",
              child: SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        color: Colors.blue,
                        value: 40,
                        title: 'To Do',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      PieChartSectionData(
                        color: Colors.orange,
                        value: 30,
                        title: 'In Progress',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      PieChartSectionData(
                        color: Colors.green,
                        value: 30,
                        title: 'Done',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildChartCard(
              title: "Weekly Productivity",
              child: SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 20,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
                            Widget text;
                            switch (value.toInt()) {
                              case 0: text = const Text('Mon', style: style); break;
                              case 1: text = const Text('Tue', style: style); break;
                              case 2: text = const Text('Wed', style: style); break;
                              case 3: text = const Text('Thu', style: style); break;
                              case 4: text = const Text('Fri', style: style); break;
                              case 5: text = const Text('Sat', style: style); break;
                              case 6: text = const Text('Sun', style: style); break;
                              default: text = const Text('', style: style); break;
                            }
                            return SideTitleWidget(meta: meta, child: text);
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.indigo)]),
                      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10, color: Colors.indigo)]),
                      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 14, color: Colors.indigo)]),
                      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 15, color: Colors.indigo)]),
                      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 13, color: Colors.indigo)]),
                      BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 10, color: Colors.indigo)]),
                      BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 5, color: Colors.indigo)]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
