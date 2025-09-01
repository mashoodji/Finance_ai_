import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_models.dart';
import '../services/firebase_auth_service.dart';

class AuthRepository {
  final FirebaseAuthService _authService;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  AuthRepository(this._authService);

  Stream<User?> authStateChanges() => _authService.authStateChanges();

  User? get currentUser => _authService.currentUser;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<AppUser?> fetchAppUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['uid'] = uid;
    return AppUser.fromMap(data);
  }

  Stream<AppUser?> streamAppUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['uid'] = uid;
      return AppUser.fromMap(data);
    });
  }

  Future<UserCredential> signUp(String email, String password,
      {String? displayName}) async {
    final cred = await _authService.signUpWithEmail(email, password);
    await _ensureUserDoc(cred.user!, displayName: displayName);
    return cred;
  }

  Future<UserCredential> signIn(String email, String password) async {
    final cred = await _authService.signInWithEmail(email, password);
    await _ensureUserDoc(cred.user!);
    return cred;
  }

  Future<UserCredential?> signInWithGoogle() async {
    final cred = await _authService.signInWithGoogle();
    if (cred != null) await _ensureUserDoc(cred.user!);
    return cred;
  }

  Future<void> signOut() => _authService.signOut();

  Future<String?> _uploadProfilePicture(File imageFile, String uid) async {
    try {
      final ref = _storage.ref().child('profile_pictures/$uid.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  Future<void> _ensureUserDoc(User user, {String? displayName}) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      String? photoURL = user.photoURL;

      // If user signed up with email and has no photo, set a default one
      if (photoURL == null && user.providerData.isNotEmpty &&
          user.providerData[0].providerId == 'password') {
        photoURL = 'https://ui-avatars.com/api/?name=${displayName ??
            user.email}&background=random';
      }

      final appUser = AppUser(
        uid: user.uid,
        email: user.email,
        displayName: displayName ?? user.displayName,
        photoURL: photoURL,
      );

      await ref.set({
        'uid': appUser.uid,
        'email': appUser.email,
        'displayName': appUser.displayName,
        'photoURL': appUser.photoURL,
        'currency': appUser.currency,
        'monthlyIncome': appUser.monthlyIncome,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? currency,
    num? monthlyIncome,
    String? phone,
    num? monthlyBudget,
    num? monthlySavingsGoal,
    String? financialGoal,
    String? riskTolerance,
  }) async {
    await _users.doc(uid).set({
      if (displayName != null) 'displayName': displayName,
      if (currency != null) 'currency': currency,
      if (monthlyIncome != null) 'monthlyIncome': monthlyIncome,
      if (phone != null) 'phone': phone,
      if (monthlyBudget != null) 'monthlyBudget': monthlyBudget,
      if (monthlySavingsGoal != null) 'monthlySavingsGoal': monthlySavingsGoal,
      if (financialGoal != null) 'financialGoal': financialGoal,
      if (riskTolerance != null) 'riskTolerance': riskTolerance,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}