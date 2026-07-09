import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        centerTitle: true,
      ),
      body: dashboardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (dashboard) {
          final totalTasks = dashboard.tasksToDo + dashboard.tasksInProgress + dashboard.tasksReview + dashboard.totalTasksDone;
          
          double toDoPct = totalTasks > 0 ? (dashboard.tasksToDo / totalTasks) * 100 : 0;
          double inProgressPct = totalTasks > 0 ? (dashboard.tasksInProgress / totalTasks) * 100 : 0;
          double reviewPct = totalTasks > 0 ? (dashboard.tasksReview / totalTasks) * 100 : 0;
          double donePct = totalTasks > 0 ? (dashboard.totalTasksDone / totalTasks) * 100 : 0;

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(dashboardProvider.notifier).fetchDashboardStats();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildChartCard(
                    context,
                    title: "Task Status Distribution",
                    child: SizedBox(
                      height: 250,
                      child: totalTasks == 0 
                        ? const Center(child: Text("No tasks available"))
                        : PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            if (toDoPct > 0)
                              PieChartSectionData(
                                color: Colors.grey,
                                value: toDoPct,
                                title: 'To Do\n${toDoPct.toStringAsFixed(1)}%',
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (inProgressPct > 0)
                              PieChartSectionData(
                                color: Colors.blue,
                                value: inProgressPct,
                                title: 'Doing\n${inProgressPct.toStringAsFixed(1)}%',
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (reviewPct > 0)
                              PieChartSectionData(
                                color: Colors.orange,
                                value: reviewPct,
                                title: 'Review\n${reviewPct.toStringAsFixed(1)}%',
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (donePct > 0)
                              PieChartSectionData(
                                color: Colors.green,
                                value: donePct,
                                title: 'Done\n${donePct.toStringAsFixed(1)}%',
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildChartCard(
                    context,
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
                            leftTitles: const AxisTitles(
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
        },
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, {required String title, required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
