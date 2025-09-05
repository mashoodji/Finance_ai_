import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_models.dart';
import '../data/services/firebase_auth_service.dart';
import '../data/repository/auth_repository.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) => FirebaseAuthService());
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.read(firebaseAuthServiceProvider)));

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges();
});

final appUserStreamProvider = StreamProvider.family<AppUser?, String>((ref, uid) {
  return ref.read(authRepositoryProvider).streamAppUser(uid);
});

class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  AuthController(this.ref) : super(const AsyncValue.loading()) {
    // Listen to Firebase auth changes
    _userSubscription = ref.read(authRepositoryProvider).authStateChanges().listen(
          (user) async {
        if (user == null) {
          state = const AsyncValue.data(null);
        } else {
          try {
            final appUser = await ref.read(authRepositoryProvider).fetchAppUser(user.uid);
            state = AsyncValue.data(appUser);
          } catch (e, st) {
            state = AsyncValue.error(e, st);
          }
        }
      },
      onError: (e, st) {
        state = AsyncValue.error(e, st);
      },
    );
  }

  final Ref ref;
  late final StreamSubscription<User?> _userSubscription;

  bool get isLoggedIn => state.value != null;
  bool get needsProfileSetup => (state.value?.profileComplete ?? false) == false && isLoggedIn;

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).signIn(email, password);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, {required String displayName}) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).signUp(email, password, displayName: displayName);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String displayName,
    required String currency,
    num? monthlyIncome,
    String? phone,
    num? monthlyBudget,
    num? monthlySavingsGoal,
    String? financialGoal,
    String? riskTolerance,
  }) async {
    final currentUser = ref.read(authRepositoryProvider).currentUser;
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      await ref.read(authRepositoryProvider).updateProfile(
        uid: currentUser.uid,
        displayName: displayName,
        currency: currency,
        monthlyIncome: monthlyIncome,
        phone: phone,
        monthlyBudget: monthlyBudget,
        monthlySavingsGoal: monthlySavingsGoal,
        financialGoal: financialGoal,
        riskTolerance: riskTolerance,
      );
      final updated = await ref.read(authRepositoryProvider).fetchAppUser(currentUser.uid);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// ✅ New method: Update full user object (for your AddEditTransactionScreen)
  Future<void> updateUser(AppUser updatedUser) async {
    try {
      await ref.read(authRepositoryProvider).updateProfile(
        uid: updatedUser.uid,
        displayName: updatedUser.displayName ?? '',
        currency: updatedUser.currency ?? 'PKR',
        monthlyIncome: updatedUser.monthlyIncome,
        phone: updatedUser.phone,
        monthlyBudget: updatedUser.monthlyBudget,
        monthlySavingsGoal: updatedUser.monthlySavingsGoal,
        financialGoal: updatedUser.financialGoal,
        riskTolerance: updatedUser.riskTolerance,
      );

      // Refresh state so UI reflects the new data
      state = AsyncValue.data(updatedUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // Reload user from Firestore
  Future<void> reloadUser() async {
    final currentUser = ref.read(authRepositoryProvider).currentUser;
    if (currentUser == null) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final appUser = await ref.read(authRepositoryProvider).fetchAppUser(currentUser.uid);
      state = AsyncValue.data(appUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    super.dispose();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<AppUser?>>((ref) {
  return AuthController(ref);
});
