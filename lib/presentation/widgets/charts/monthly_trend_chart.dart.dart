// lib/presentation/screens/dashboard/widgets/monthly_trend_chart.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/chart_utils.dart';
import '../../../state/chart_provider.dart';

class MonthlyTrendChart extends ConsumerWidget {
  const MonthlyTrendChart({super.key});

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
              'Monthly Trends',
              style: ChartStyles.chartTitle,
            ),
            const SizedBox(height: 16),
            chartDataAsync.when(
              data: (chartData) {
                if (chartData.monthlyExpenses.isEmpty &&
                    chartData.monthlyIncome.isEmpty) {
                  return const _EmptyChartPlaceholder(
                      message: 'No trend data available');
                }
                return SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData:
                      FlGridData(show: true, drawVerticalLine: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: _bottomTitles,
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: _leftTitles,
                        ),
                        rightTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        _incomeLine(chartData.monthlyIncome),
                        _expenseLine(chartData.monthlyExpenses),
                      ],
                      minX: 1,
                      maxX: _getMaxX(
                          chartData.monthlyIncome, chartData.monthlyExpenses)
                          .toDouble(),
                      minY: 0,
                      maxY: _getMaxY(
                          chartData.monthlyIncome, chartData.monthlyExpenses),
                    ),
                  ),
                );
              },
              loading: () =>
              const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  _buildErrorWidget(error.toString()),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _incomeLine(Map<DateTime, double> monthlyIncome) {
    final sortedEntries = monthlyIncome.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries.map((entry) {
      final month = entry.key.month.toDouble(); // x-axis = month number
      final amount = entry.value; // y-axis = income
      return FlSpot(month, amount);
    }).toList();

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: ChartColors.incomeColor,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
    );
  }

  LineChartBarData _expenseLine(Map<DateTime, double> monthlyExpenses) {
    final sortedEntries = monthlyExpenses.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries.map((entry) {
      final month = entry.key.month.toDouble(); // x-axis = month number
      final amount = entry.value; // y-axis = expense
      return FlSpot(month, amount);
    }).toList();

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: ChartColors.expenseColor,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
    );
  }

  SideTitles get _bottomTitles => SideTitles(
    showTitles: true,
    getTitlesWidget: (value, meta) {
      if (value < 1 || value > 12) return const SizedBox();
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          DateFormat('MMM').format(DateTime(2023, value.toInt())),
          style: ChartStyles.chartLabel,
        ),
      );
    },
  );

  SideTitles get _leftTitles => SideTitles(
    showTitles: true,
    getTitlesWidget: (value, meta) {
      return Text(
        'PKR ${value.toInt()}',
        style: ChartStyles.chartLabel,
      );
    },
  );

  double _getMaxY(
      Map<DateTime, double> income, Map<DateTime, double> expense) {
    final maxIncome = income.values
        .fold(0.0, (max, amount) => amount > max ? amount : max);
    final maxExpense = expense.values
        .fold(0.0, (max, amount) => amount > max ? amount : max);
    return (maxIncome > maxExpense ? maxIncome : maxExpense) * 1.2;
  }

  int _getMaxX(
      Map<DateTime, double> income, Map<DateTime, double> expense) {
    final allMonths = {...income.keys, ...expense.keys};
    if (allMonths.isEmpty) return 1;
    return allMonths.map((d) => d.month).reduce((a, b) => a > b ? a : b);
  }

  Widget _buildErrorWidget(String error) {
    return const _EmptyChartPlaceholder(
        message: 'Error loading trend data');
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
            Icon(Icons.trending_up,
                size: 48, color: Colors.grey.shade400),
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
