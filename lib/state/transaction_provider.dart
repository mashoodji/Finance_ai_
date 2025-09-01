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
