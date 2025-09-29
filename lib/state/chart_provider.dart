// lib/presentation/state/chart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance/data/models/transactions_model.dart';
import 'package:finance/state/auth_provider.dart';

import 'expense_provider.dart';

final chartDataProvider = StreamProvider.autoDispose<ChartData>((ref) {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final user = ref.watch(authControllerProvider).value;

  if (user == null) {
    return const Stream.empty();
  }

  return transactionRepository.getTransactions(user.uid).map((transactions) {
    return ChartData.fromTransactions(transactions);
  });
});

class ChartData {
  final List<TransactionModel> transactions;
  final Map<String, double> expenseByCategory;
  final Map<String, double> incomeByCategory;
  final Map<DateTime, double> monthlyExpenses;
  final Map<DateTime, double> monthlyIncome;
  final double totalIncome;
  final double totalExpense;

  ChartData({
    required this.transactions,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.monthlyExpenses,
    required this.monthlyIncome,
    required this.totalIncome,
    required this.totalExpense,
  });

  factory ChartData.fromTransactions(List<TransactionModel> transactions) {
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    final incomes = transactions.where((t) => t.type == TransactionType.income).toList();

    // Category-wise data
    final expenseByCategory = <String, double>{};
    final incomeByCategory = <String, double>{};

    for (var expense in expenses) {
      expenseByCategory.update(
        expense.category,
            (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    for (var income in incomes) {
      incomeByCategory.update(
        income.category,
            (value) => value + income.amount,
        ifAbsent: () => income.amount,
      );
    }

    // Monthly data
    final monthlyExpenses = <DateTime, double>{};
    final monthlyIncome = <DateTime, double>{};

    for (var expense in expenses) {
      final monthStart = DateTime(expense.date.year, expense.date.month);
      monthlyExpenses.update(
        monthStart,
            (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    for (var income in incomes) {
      final monthStart = DateTime(income.date.year, income.date.month);
      monthlyIncome.update(
        monthStart,
            (value) => value + income.amount,
        ifAbsent: () => income.amount,
      );
    }

    return ChartData(
      transactions: transactions,
      expenseByCategory: expenseByCategory,
      incomeByCategory: incomeByCategory,
      monthlyExpenses: monthlyExpenses,
      monthlyIncome: monthlyIncome,
      totalIncome: incomes.fold(0.0, (sum, item) => sum + item.amount),
      totalExpense: expenses.fold(0.0, (sum, item) => sum + item.amount),
    );
  }
}