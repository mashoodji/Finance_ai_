import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/animation.dart';
import 'dart:math';
import '../../../data/models/user_models.dart';
import '../../../state/auth_provider.dart';
import '../auth/login_screen.dart';
import '../auth/profile_setup_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  static const routePath = '/dashboard';
  static const routeName = 'dashboard';
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authControllerProvider);
    final user = userAsync.value;

    // Convert num to double and handle null values
    final monthlyIncome = (user?.monthlyIncome ?? 0).toDouble();
    final monthlyBudget = (user?.monthlyBudget ?? 0).toDouble();
    final monthlySavingsGoal = (user?.monthlySavingsGoal ?? 0).toDouble();
    final expenses = monthlyIncome > 0 && monthlyBudget > 0
        ? monthlyIncome - monthlyBudget
        : 0;
    final savingsProgress = monthlySavingsGoal > 0
        ? (monthlyBudget > 0 ? (monthlyBudget / monthlySavingsGoal).clamp(0.0, 1.0) : 0.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinanceAI Dashboard'),
        actions: [
          // Profile Icon
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
              );
            },
          ),
          // Logout
          IconButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          // Refresh user data using the new reloadUser method
          await ref.read(authControllerProvider.notifier).reloadUser();
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // 1. Welcome & Profile Section
                  AnimatedProfileCard(user: user),
                  const SizedBox(height: 20),

                  // 2. Financial Overview Grid
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    children: [
                      AnimatedDashboardCard(
                        title: 'Monthly Income',
                        value: '${user.currency ?? 'PKR'} ${monthlyIncome.toStringAsFixed(2)}',
                        icon: Icons.trending_up,
                        color: Colors.green,
                        showEdit: monthlyIncome == 0,
                        onEdit: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                          );
                        },
                      ),
                      AnimatedDashboardCard(
                        title: 'Monthly Budget',
                        value: '${user.currency ?? 'PKR'} ${monthlyBudget.toStringAsFixed(2)}',
                        icon: Icons.pie_chart,
                        color: Colors.blue,
                        showEdit: monthlyBudget == 0,
                        onEdit: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                          );
                        },
                      ),
                      AnimatedDashboardCard(
                        title: 'Monthly Expenses',
                        value: '${user.currency ?? 'PKR'} ${expenses.toStringAsFixed(2)}',
                        icon: Icons.trending_down,
                        color: expenses > 0 ? Colors.redAccent : Colors.grey,
                      ),
                      AnimatedDashboardCard(
                        title: 'Savings Goal',
                        value: '${user.currency ?? 'PKR'} ${monthlySavingsGoal.toStringAsFixed(2)}',
                        icon: Icons.savings,
                        color: Colors.teal,
                        showEdit: monthlySavingsGoal == 0,
                        onEdit: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Quick Actions
                  AnimatedQuickActions(),
                  const SizedBox(height: 24),

                  // 4. Financial Goals Progress with Circular Chart
                  if (monthlySavingsGoal > 0)
                    AnimatedSavingsProgressCard(
                      currency: user.currency ?? 'PKR',
                      current: monthlyBudget,
                      goal: monthlySavingsGoal,
                      progress: savingsProgress,
                    ),

                  const SizedBox(height: 20),

                  // 5. Recent Transactions
                  AnimatedSectionTitle(title: "Recent Transactions"),
                  const SizedBox(height: 12),
                  const AnimatedTransactionTile(icon: Icons.shopping_cart, label: "Grocery", amount: "-\$120", color: Colors.orange),
                  const AnimatedTransactionTile(icon: Icons.local_gas_station, label: "Fuel", amount: "-\$50", color: Colors.red),
                  const AnimatedTransactionTile(icon: Icons.work, label: "Salary", amount: "+\$2,000", color: Colors.green),
                  const SizedBox(height: 24),

                  // 6. Financial Health Indicator
                  AnimatedFinancialHealthCard(
                    income: monthlyIncome,
                    budget: monthlyBudget,
                    savingsGoal: monthlySavingsGoal,
                  ),
                  const SizedBox(height: 16),

                  // 7. Setup Prompt if data is missing
                  if (monthlyIncome == 0 || monthlyBudget == 0)
                    AnimatedSetupPrompt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Animated Profile Card
class AnimatedProfileCard extends StatelessWidget {
  final AppUser user;

  const AnimatedProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final String name = user.displayName ?? user.email ?? "User";
    final String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "?";

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              shadowColor: Colors.blue.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  children: [
                    // Avatar with first letter
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade600,
                      child: Text(
                        firstLetter,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Welcome back,",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            name ,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Currency: ${user.currency ?? 'PKR'}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
// Animated Dashboard Card
class AnimatedDashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool showEdit;
  final VoidCallback? onEdit;

  const AnimatedDashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.showEdit = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.scale(
            scale: 0.95 + (animValue * 0.05),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
              shadowColor: color.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: color.withOpacity(0.15),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        if (showEdit)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16),
                            onPressed: onEdit,
                            tooltip: 'Edit $title',
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


// Animated Quick Actions
class AnimatedQuickActions extends StatelessWidget {
  final List<Map<String, dynamic>> actions = const [
    {'icon': Icons.add, 'label': 'Add Expense'},
    {'icon': Icons.add_card, 'label': 'Add Income'},
    {'icon': Icons.bar_chart, 'label': 'Reports'},
    {'icon': Icons.settings, 'label': 'Settings'},
  ];

  const AnimatedQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                actions[index]['icon'],
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              actions[index]['label'],
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

// Animated Savings Progress Card with Circular Chart
class AnimatedSavingsProgressCard extends StatelessWidget {
  final String currency;
  final double current;
  final double goal;
  final double progress;

  const AnimatedSavingsProgressCard({
    super.key,
    required this.currency,
    required this.current,
    required this.goal,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: progress),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4, // slight shadow for a professional look
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Circular Progress Indicator
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: value, // between 0 and 1
                          strokeWidth: 10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            value >= 1.0 ? Colors.green : Colors.blue,
                          ),
                          backgroundColor: Colors.grey.shade300,
                        ),
                      ),
                      Text(
                        "${(value * 100).toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Monthly Savings Goal",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Progress: $currency ${current.toStringAsFixed(2)} / $currency ${goal.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          color: value >= 1.0 ? Colors.green : Colors.blue,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}


// Animated Section Title
class AnimatedSectionTitle extends StatelessWidget {
  final String title;

  const AnimatedSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((1 - value) * 20, 0),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        );
      },
    );
  }
}

// Animated Transaction Tile
class AnimatedTransactionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color color;

  const AnimatedTransactionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, color: color, size: 20),
                ),
                title: Text(label),
                trailing: Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Animated Financial Health Card
class AnimatedFinancialHealthCard extends StatelessWidget {
  final double income;
  final double budget;
  final double savingsGoal;

  const AnimatedFinancialHealthCard({
    super.key,
    required this.income,
    required this.budget,
    required this.savingsGoal,
  });

  Color _getFinancialHealthColor() {
    if (income == 0 || budget == 0) return Colors.grey;
    if (budget > income) return Colors.red;
    if (savingsGoal > 0 && budget >= savingsGoal) return Colors.green;
    return Colors.blue;
  }

  IconData _getFinancialHealthIcon() {
    if (income == 0 || budget == 0) return Icons.help;
    if (budget > income) return Icons.warning;
    if (savingsGoal > 0 && budget >= savingsGoal) return Icons.celebration;
    return Icons.trending_up;
  }

  String _getFinancialHealthMessage() {
    if (income == 0 || budget == 0) return "Complete your profile to see financial health analysis";
    if (budget > income) return "Your budget exceeds your income. Consider adjusting your spending.";
    if (savingsGoal > 0 && budget >= savingsGoal) return "Great job! You're meeting your savings goal.";
    if (savingsGoal > 0) return "You're on track to meet your savings goal. Keep it up!";
    return "Your finances look healthy. Consider setting a savings goal.";
  }

  @override
  Widget build(BuildContext context) {
    final color = _getFinancialHealthColor();
    final icon = _getFinancialHealthIcon();
    final message = _getFinancialHealthMessage();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + (value * 0.05),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: color.withOpacity(0.1),
              child: ListTile(
                leading: Icon(icon, color: color),
                title: const Text("Financial Health"),
                subtitle: Text(message, style: TextStyle(color: color)),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Animated Setup Prompt
class AnimatedSetupPrompt extends StatelessWidget {
  const AnimatedSetupPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: value,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(Icons.info, color: Colors.orange),
                title: const Text("Complete Your Profile"),
                subtitle: const Text("Set up your financial information to get personalized insights"),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                    );
                  },
                  child: const Text("Setup"),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}