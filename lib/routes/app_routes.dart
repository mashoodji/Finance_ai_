import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/auth_provider.dart';

// Screens
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/auth/profile_setup_screen.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/expense/add_expense_screen.dart';
import '../presentation/screens/expense/expense_list_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: SplashScreen.routePath,
    refreshListenable:
    GoRouterRefreshStream(ref.watch(authStateChangesProvider.stream)),
    routes: [
      GoRoute(
          path: SplashScreen.routePath,
          name: SplashScreen.routeName,
          builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: LoginScreen.routePath,
          name: LoginScreen.routeName,
          builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: SignUpScreen.routePath,
          name: SignUpScreen.routeName,
          builder: (_, __) => const SignUpScreen()),
      GoRoute(
          path: ProfileSetupScreen.routePath,
          name: ProfileSetupScreen.routeName,
          builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(
          path: DashboardScreen.routePath,
          name: DashboardScreen.routeName,
          builder: (_, __) => const DashboardScreen()),

      // 🔹 Phase 2 Routes
      GoRoute(
        path: ExpenseListScreen.routePath,
        name: ExpenseListScreen.routeName,
        builder: (context, state) {
          final userId = state.extra as String;
          return ExpenseListScreen(userId: userId);
        },
      ),
      GoRoute(
        path: AddExpenseScreen.routePath,
        name: AddExpenseScreen.routeName,
        builder: (context, state) {
          final userId = state.extra as String;
          return AddExpenseScreen(userId: userId);
        },
      ),
    ],
    redirect: (context, state) {
      final authCtrl = ref.read(authControllerProvider.notifier);
      final isLoggedIn = authCtrl.isLoggedIn;
      final needsProfile = authCtrl.needsProfileSetup;

      final loggingIn = state.matchedLocation == LoginScreen.routePath ||
          state.matchedLocation == SignUpScreen.routePath;

      if (state.matchedLocation == SplashScreen.routePath) return null;

      if (!isLoggedIn) {
        return loggingIn ? null : LoginScreen.routePath;
      }

      if (isLoggedIn &&
          needsProfile &&
          state.matchedLocation != ProfileSetupScreen.routePath) {
        return ProfileSetupScreen.routePath;
      }

      if (isLoggedIn &&
          !needsProfile &&
          (loggingIn ||
              state.matchedLocation == ProfileSetupScreen.routePath)) {
        return DashboardScreen.routePath;
      }

      return null;
    },
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription =
        stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
