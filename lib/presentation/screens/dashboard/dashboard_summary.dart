// lib/presentation/screens/dashboard/widgets/dashboard_summary.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/chart_provider.dart';

class DashboardSummary extends ConsumerWidget {
  const DashboardSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartDataAsync = ref.watch(chartDataProvider);

    return chartDataAsync.when(
      data: (chartData) {
        final balance = chartData.totalIncome - chartData.totalExpense;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.green.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Current Balance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PKR ${balance.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: balance >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    'Income',
                    chartData.totalIncome,
                    Colors.green,
                    Icons.arrow_downward,
                  ),
                  _buildStatItem(
                    context,
                    'Expenses',
                    chartData.totalExpense,
                    Colors.red,
                    Icons.arrow_upward,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingSummary(),
      error: (error, stack) => _buildErrorSummary(error.toString()),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, double amount, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PKR ${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorSummary(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(
            'Error loading summary',
            style: TextStyle(color: Colors.red.shade700),
          ),
        ],
      ),
    );
  }
}