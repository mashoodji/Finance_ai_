// lib/presentation/screens/dashboard/widgets/income_expense_comparison.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';


import '../../../core/utils/chart_utils.dart';
import '../../../state/chart_provider.dart';

class IncomeExpenseComparison extends ConsumerWidget {
  const IncomeExpenseComparison({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartDataAsync = ref.watch(chartDataProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income vs Expenses',
              style: ChartStyles.chartTitle,
            ),
            const SizedBox(height: 16),
            chartDataAsync.when(
              data: (chartData) {
                if (chartData.totalIncome == 0 && chartData.totalExpense == 0) {
                  return const _EmptyChartPlaceholder(message: 'No comparison data');
                }
                return SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(chartData.totalIncome, chartData.totalExpense),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: chartData.totalIncome,
                              color: ChartColors.incomeColor,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: chartData.totalExpense,
                              color: ChartColors.expenseColor,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final labels = ['Income', 'Expenses'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  labels[value.toInt()],
                                  style: ChartStyles.chartLabel,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                'PKR ${value.toInt()}',
                                style: ChartStyles.chartLabel,
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorWidget(error.toString()),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxY(double income, double expense) {
    final maxValue = income > expense ? income : expense;
    return maxValue * 1.2;
  }

  Widget _buildErrorWidget(String error) {
    return const _EmptyChartPlaceholder(message: 'Error loading comparison');
  }
}

class _EmptyChartPlaceholder extends StatelessWidget {
  final String message;

  const _EmptyChartPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}