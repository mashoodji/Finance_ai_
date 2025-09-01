import '../models/transactions_model.dart';
import '../services/firestore_service.dart';

class TransactionRepository {
  final FirestoreService firestoreService;
  TransactionRepository(this.firestoreService);

  Future<void> addTransaction(TransactionModel transaction) =>
      firestoreService.addTransaction(transaction);

  Stream<List<TransactionModel>> getTransactions(String userId) =>
      firestoreService.getTransactions(userId);

  Future<void> updateTransaction(TransactionModel transaction) =>
      firestoreService.updateTransaction(transaction);

  Future<void> deleteTransaction(String id) =>
      firestoreService.deleteTransaction(id);
}
