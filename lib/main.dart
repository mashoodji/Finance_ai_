import 'package:finance/presentation/screens/auth/login_screen.dart';
import 'package:finance/presentation/screens/auth/profile_setup_screen.dart';
import 'package:finance/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
import 'routes/app_routes.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: FinanceAIApp()));
}

class FinanceAIApp extends ConsumerWidget {
  const FinanceAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final router = ref.watch(appRouterProvider);
    // return MaterialApp.router(
    //   debugShowCheckedModeBanner: false,
    //   title: 'FinanceAI',
    //   theme: AppTheme.light,
    //   routerConfig: router,
    //
    // );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinanceAI',
      theme: AppTheme.light,
      home: const LoginScreen(),
      //home: const DashboardScreen(),
      // home: const TransactionsScreen(),
    );

  }
}