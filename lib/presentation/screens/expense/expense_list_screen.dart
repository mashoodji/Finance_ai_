import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/transaction_provider.dart';
import '../../../data/models/transactions_model.dart';

class ExpenseListScreen extends ConsumerWidget {
  static const String routePath = "/expenses";
  static const String routeName = "expenses";

  final String userId;
  const ExpenseListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionListProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text("Transactions")),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text("No transactions yet."));
          }
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final t = transactions[index];
              return ListTile(
                title: Text("${t.category} - \$${t.amount}"),
                subtitle: Text(t.date.toLocal().toString()),
                trailing: Text(t.type == TransactionType.expense ? "Expense" : "Income"),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}
