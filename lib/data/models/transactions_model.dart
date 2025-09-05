// lib/data/models/transactions_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final DateTime date;
  final TransactionType type;
  final String? notes;
  final int month; // Added for monthly tracking
  final int year;  // Added for yearly tracking

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    this.notes,
  }) : month = date.month,
        year = date.year;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'type': type == TransactionType.income ? 'income' : 'expense',
      'notes': notes,
      'month': month,
      'year': year,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      type: map['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      notes: map['notes'],
    );
  }
}