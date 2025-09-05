import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String currency;
  final double monthlyIncome;
  final String? phone;
  final double? monthlyBudget;
  final double? monthlySavingsGoal;
  final String? financialGoal;
  final String? riskTolerance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.currency = 'USD',
    this.monthlyIncome = 0,
    this.phone,
    this.monthlyBudget,
    this.monthlySavingsGoal,
    this.financialGoal,
    this.riskTolerance,
    this.createdAt,
    this.updatedAt,
  });

  bool get profileComplete => displayName != null && displayName!.isNotEmpty && currency.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoURL': photoURL,
    'currency': currency,
    'monthlyIncome': monthlyIncome,
    'phone': phone,
    'monthlyBudget': monthlyBudget,
    'monthlySavingsGoal': monthlySavingsGoal,
    'financialGoal': financialGoal,
    'riskTolerance': riskTolerance,
    'createdAt': createdAt,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      email: map['email'],
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      currency: map['currency'] ?? 'USD',
      monthlyIncome: (map['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      phone: map['phone'],
      monthlyBudget: (map['monthlyBudget'] as num?)?.toDouble(),
      monthlySavingsGoal: (map['monthlySavingsGoal'] as num?)?.toDouble(),
      financialGoal: map['financialGoal'],
      riskTolerance: map['riskTolerance'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }


  AppUser copyWith({
    String? email,
    String? displayName,
    String? photoURL,
    String? currency,
    double? monthlyIncome,
    String? phone,
    double? monthlyBudget,
    double? monthlySavingsGoal,
    String? financialGoal,
    String? riskTolerance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      currency: currency ?? this.currency,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      phone: phone ?? this.phone,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      monthlySavingsGoal: monthlySavingsGoal ?? this.monthlySavingsGoal,
      financialGoal: financialGoal ?? this.financialGoal,
      riskTolerance: riskTolerance ?? this.riskTolerance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}