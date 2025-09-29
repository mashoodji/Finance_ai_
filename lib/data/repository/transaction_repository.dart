// lib/data/repository/transaction_repository.dart
import '../models/transactions_model.dart';
import '../services/firestore_service.dart';

class TransactionRepository {
  final FirestoreService firestoreService;
  TransactionRepository(this.firestoreService);

  // Existing methods...
  Future<void> addTransaction(TransactionModel transaction) =>
      firestoreService.addTransaction(transaction);

  Stream<List<TransactionModel>> getTransactions(String userId) =>
      firestoreService.getTransactions(userId);

  Future<void> updateTransaction(TransactionModel transaction) =>
      firestoreService.updateTransaction(transaction);

  Future<void> deleteTransaction(String userId, String id) =>
      firestoreService.deleteTransaction(userId, id);

  // NEW: Chart data methods
  Stream<List<CategorySpending>> getCategorySpending(String userId, TransactionType type) =>
      firestoreService.getCategorySpending(userId, type);

  Stream<List<MonthlySummary>> getMonthlySummary(String userId, int year) =>
      firestoreService.getMonthlySummary(userId, year);

  Stream<FinancialSummary> getFinancialSummary(String userId) =>
      firestoreService.getFinancialSummary(userId);
}

// NEW: Data models for charts
class CategorySpending {
  final String category;
  final double amount;
  final double percentage;

  CategorySpending({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class MonthlySummary {
  final int month;
  final int year;
  final double income;
  final double expense;
  final double balance;

  MonthlySummary({
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
    required this.balance,
  });
}

class FinancialSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int transactionCount;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactionCount,
  });
}