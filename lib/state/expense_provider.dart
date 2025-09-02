// lib/state/expense_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transactions_model.dart';
import '../data/repository/transaction_repository.dart';
import '../data/services/firestore_service.dart';
import 'auth_provider.dart';

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<TransactionModel>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionNotifier(repository, user?.uid ?? '');
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(firestoreServiceProvider));
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  final TransactionRepository _repository;
  final String _userId;

  TransactionNotifier(this._repository, this._userId) : super([]) {
    loadTransactions();
  }

  // Add a transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    await _repository.addTransaction(transaction);
    // State will update automatically via the stream
  }

  // Update a transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _repository.updateTransaction(transaction);
    // State will update automatically via the stream
  }

  // Delete a transaction
  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(_userId, id);
    // State will update automatically via the stream
  }

  // Load transactions for a user
  void loadTransactions() {
    _repository.getTransactions(_userId).listen((transactions) {
      state = transactions;
    });
  }
}