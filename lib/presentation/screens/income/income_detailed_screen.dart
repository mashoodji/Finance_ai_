// income_detailed_screen.dart (updated)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/transactions_model.dart';
import '../../../../state/auth_provider.dart';
import '../../../data/repository/transaction_repository.dart';
import '../../../state/transaction_provider.dart';
import 'transaction_edit_dialog.dart';

class IncomeDetailedScreen extends ConsumerWidget {
  static const routeName = 'income_detailed';

  const IncomeDetailedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // get logged-in user
    final user = ref.watch(authControllerProvider).value;
    final userId = user?.uid ?? "";

    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No user logged in")),
      );
    }

    final transactionsAsync = ref.watch(transactionListProvider(userId));
    final transactionRepository = ref.read(transactionRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Income Details"),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final incomes = transactions
              .where((t) => t.type == TransactionType.income)
              .toList();

          final totalIncome =
          incomes.fold<double>(0, (sum, t) => sum + t.amount);

          if (incomes.isEmpty) {
            return const Center(child: Text("No incomes recorded"));
          }

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: const Text(
                    "Total Income",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    "PKR ${totalIncome.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: incomes.length,
                  itemBuilder: (context, index) {
                    final income = incomes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.arrow_downward,
                            color: Colors.green),
                        title: Text(income.category),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat.yMMMd().format(income.date)),
                            if (income.notes != null && income.notes!.isNotEmpty)
                              Text(
                                income.notes!,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing: Text(
                          "PKR ${income.amount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => _showOptionsDialog(context, income, transactionRepository, userId),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, TransactionModel income, TransactionRepository transactionRepository, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(income.category),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Amount: PKR ${income.amount.toStringAsFixed(2)}"),
              Text("Date: ${DateFormat.yMMMd().format(income.date)}"),
              if (income.notes != null && income.notes!.isNotEmpty)
                Text("Notes: ${income.notes}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final updatedTransaction = await showDialog<TransactionModel>(
                  context: context,
                  builder: (context) => TransactionEditDialog(transaction: income),
                );

                if (updatedTransaction != null) {
                  await transactionRepository.updateTransaction(updatedTransaction);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Income updated successfully')),
                  );
                }
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Income'),
                    content: const Text('Are you sure you want to delete this income?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (shouldDelete == true) {
                  await transactionRepository.deleteTransaction(userId, income.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Income deleted successfully')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}