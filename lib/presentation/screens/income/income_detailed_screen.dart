import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/transactions_model.dart';
import '../../../../state/auth_provider.dart';
import '../../../state/transaction_provider.dart';

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
                        subtitle: Text(DateFormat.yMMMd().format(income.date)),
                        trailing: Text(
                          "PKR ${income.amount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
}
