// lib/data/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transactions_model.dart';
import '../../data/repository/transaction_repository.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Existing methods...
  Future<void> addTransaction(TransactionModel transaction) async {
    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toMap());
  }

  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data()))
        .toList());
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  Future<void> deleteTransaction(String userId, String id) async {
    await _firestore.collection('transactions').doc(id).delete();
  }

  // NEW: Chart data queries
  Stream<List<CategorySpending>> getCategorySpending(String userId, TransactionType type) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type == TransactionType.income ? 'income' : 'expense')
        .snapshots()
        .map((snapshot) {
      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();

      // Group by category and calculate totals
      final categoryMap = <String, double>{};
      double total = 0;

      for (final transaction in transactions) {
        categoryMap[transaction.category] =
            (categoryMap[transaction.category] ?? 0) + transaction.amount;
        total += transaction.amount;
      }

      // Convert to CategorySpending objects
      return categoryMap.entries.map((entry) {
        return CategorySpending(
          category: entry.key,
          amount: entry.value,
          percentage: total > 0 ? (entry.value / total) * 100 : 0,
        );
      }).toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
    });
  }

  Stream<List<MonthlySummary>> getMonthlySummary(String userId, int year) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('year', isEqualTo: year)
        .snapshots()
        .map((snapshot) {
      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();

      // Group by month
      final monthlyMap = <int, MonthlySummary>{};

      for (final transaction in transactions) {
        final month = transaction.month;
        if (!monthlyMap.containsKey(month)) {
          monthlyMap[month] = MonthlySummary(
            month: month,
            year: year,
            income: 0,
            expense: 0,
            balance: 0,
          );
        }

        final current = monthlyMap[month]!;
        if (transaction.type == TransactionType.income) {
          monthlyMap[month] = MonthlySummary(
            month: month,
            year: year,
            income: current.income + transaction.amount,
            expense: current.expense,
            balance: current.balance + transaction.amount,
          );
        } else {
          monthlyMap[month] = MonthlySummary(
            month: month,
            year: year,
            income: current.income,
            expense: current.expense + transaction.amount,
            balance: current.balance - transaction.amount,
          );
        }
      }

      // Fill missing months and sort
      final result = <MonthlySummary>[];
      for (int month = 1; month <= 12; month++) {
        if (monthlyMap.containsKey(month)) {
          result.add(monthlyMap[month]!);
        } else {
          result.add(MonthlySummary(
            month: month,
            year: year,
            income: 0,
            expense: 0,
            balance: 0,
          ));
        }
      }

      return result;
    });
  }

  Stream<FinancialSummary> getFinancialSummary(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();

      double totalIncome = 0;
      double totalExpense = 0;

      for (final transaction in transactions) {
        if (transaction.type == TransactionType.income) {
          totalIncome += transaction.amount;
        } else {
          totalExpense += transaction.amount;
        }
      }

      return FinancialSummary(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: totalIncome - totalExpense,
        transactionCount: transactions.length,
      );
    });
  }
}