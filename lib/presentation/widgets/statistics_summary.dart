// lib/presentation/widgets/statistics_summary.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/transaction_provider.dart';

class StatisticsSummary extends ConsumerWidget {
  final String userId;

  const StatisticsSummary({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financialSummaryAsync = ref.watch(financialSummaryProvider(userId));

    return financialSummaryAsync.when(
      data: (summary) {
        return Row(
          children: [
            // Total Income Card
            Expanded(
              child: _buildSummaryCard(
                'Total Income',
                'PKR ${summary.totalIncome.toStringAsFixed(2)}',
                Colors.green,
                Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 8),
            // Total Expense Card
            Expanded(
              child: _buildSummaryCard(
                'Total Expense',
                'PKR ${summary.totalExpense.toStringAsFixed(2)}',
                Colors.red,
                Icons.arrow_upward,
              ),
            ),
            const SizedBox(width: 8),
            // Balance Card
            Expanded(
              child: _buildSummaryCard(
                'Balance',
                'PKR ${summary.balance.toStringAsFixed(2)}',
                summary.balance >= 0 ? Colors.blue : Colors.orange,
                summary.balance >= 0 ? Icons.trending_up : Icons.trending_down,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}