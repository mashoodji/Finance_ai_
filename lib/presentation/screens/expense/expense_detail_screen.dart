// expense_detailed_screen.dart (updated)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/transactions_model.dart';
import '../../../../state/auth_provider.dart';
import '../../../data/repository/transaction_repository.dart';
import '../../../state/transaction_provider.dart';
import '../income/transaction_edit_dialog.dart';

class ExpenseDetailedScreen extends ConsumerWidget {
  static const routeName = 'expense_detailed';

  const ExpenseDetailedScreen({super.key});

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
        title: const Text("Expense Details"),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final expenses = transactions
              .where((t) => t.type == TransactionType.expense)
              .toList();

          final totalExpense =
          expenses.fold<double>(0, (sum, t) => sum + t.amount);

          if (expenses.isEmpty) {
            return const Center(child: Text("No expenses recorded"));
          }

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: const Text(
                    "Total Expenses",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    "PKR ${totalExpense.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.arrow_upward,
                            color: Colors.red),
                        title: Text(expense.category),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat.yMMMd().format(expense.date)),
                            if (expense.notes != null && expense.notes!.isNotEmpty)
                              Text(
                                expense.notes!,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing: Text(
                          "PKR ${expense.amount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => _showOptionsDialog(context, expense, transactionRepository, userId),
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

  void _showOptionsDialog(BuildContext context, TransactionModel expense, TransactionRepository transactionRepository, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(expense.category),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Amount: PKR ${expense.amount.toStringAsFixed(2)}"),
              Text("Date: ${DateFormat.yMMMd().format(expense.date)}"),
              if (expense.notes != null && expense.notes!.isNotEmpty)
                Text("Notes: ${expense.notes}"),
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
                  builder: (context) => TransactionEditDialog(transaction: expense),
                );

                if (updatedTransaction != null) {
                  await transactionRepository.updateTransaction(updatedTransaction);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense updated successfully')),
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
                    title: const Text('Delete Expense'),
                    content: const Text('Are you sure you want to delete this expense?'),
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
                  await transactionRepository.deleteTransaction(userId, expense.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense deleted successfully')),
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