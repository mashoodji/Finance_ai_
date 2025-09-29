// lib/state/transaction_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transactions_model.dart';
import '../data/repository/transaction_repository.dart';
import '../data/services/firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final transactionRepositoryProvider =
Provider<TransactionRepository>((ref) => TransactionRepository(ref.read(firestoreServiceProvider)));

final transactionListProvider =
StreamProvider.family<List<TransactionModel>, String>((ref, userId) {
  return ref.read(transactionRepositoryProvider).getTransactions(userId);
});

final transactionControllerProvider =
Provider<TransactionRepository>((ref) => ref.read(transactionRepositoryProvider));

// NEW: Chart data providers
final categorySpendingProvider =
StreamProvider.family<List<CategorySpending>, ({String userId, TransactionType type})>(
      (ref, params) {
    return ref.read(transactionRepositoryProvider).getCategorySpending(params.userId, params.type);
  },
);

final monthlySummaryProvider =
StreamProvider.family<List<MonthlySummary>, ({String userId, int year})>(
      (ref, params) {
    return ref.read(transactionRepositoryProvider).getMonthlySummary(params.userId, params.year);
  },
);

final financialSummaryProvider =
StreamProvider.family<FinancialSummary, String>(
      (ref, userId) {
    return ref.read(transactionRepositoryProvider).getFinancialSummary(userId);
  },
);