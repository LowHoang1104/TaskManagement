import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/dashboard_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Analytics Overview'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Stats Summary
                  Row(
                    children: [
                      _buildSummaryBento(
                        context,
                        title: 'Total Tasks',
                        value: totalTasks.toString(),
                        icon: Icons.task_alt_rounded,
                        color: AppColors.primary,
                      ).animate().slideX(begin: -0.1).fadeIn(),
                      const SizedBox(width: AppSizes.lg),
                      _buildSummaryBento(
                        context,
                        title: 'Completed',
                        value: dashboard.totalTasksDone.toString(),
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                      ).animate().slideX(begin: 0.1).fadeIn(),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // Pie Chart Bento
                  _buildChartCard(
                    context,
                    title: "Task Status Distribution",
                    child: SizedBox(
                      height: 220,
                      child: totalTasks == 0 
                        ? const Center(child: Text("No tasks available"))
                        : PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 50,
                          sections: [
                            if (toDoPct > 0)
                              PieChartSectionData(
                                color: AppColors.grey400,
                                value: toDoPct,
                                title: '${toDoPct.toStringAsFixed(0)}%',
                                radius: 45,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (inProgressPct > 0)
                              PieChartSectionData(
                                color: AppColors.info,
                                value: inProgressPct,
                                title: '${inProgressPct.toStringAsFixed(0)}%',
                                radius: 55,
                                titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (reviewPct > 0)
                              PieChartSectionData(
                                color: AppColors.warning,
                                value: reviewPct,
                                title: '${reviewPct.toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (donePct > 0)
                              PieChartSectionData(
                                color: AppColors.success,
                                value: donePct,
                                title: '${donePct.toStringAsFixed(0)}%',
                                radius: 60,
                                titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                          ],
                        ),
                      ).animate().scale(delay: 300.ms, duration: 500.ms, curve: Curves.easeOutBack),
                    ),
                  ).animate().slideY(begin: 0.1, delay: 200.ms).fadeIn(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x, 
      barRods: [
        BarChartRodData(
          toY: y, 
          color: color, 
          width: 16,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
        )
      ]
    );
  }

  Widget _buildSummaryBento(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, {required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey200.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSizes.xl),
          child,
        ],
      ),
    );
  }
}
