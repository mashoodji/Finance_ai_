import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/animation.dart';
import '../../../data/models/transactions_model.dart';
import '../../../data/models/user_models.dart';
import '../../../state/auth_provider.dart';
import '../../../state/expense_provider.dart';
import '../auth/login_screen.dart';
import '../auth/profile_setup_screen.dart';
import '../expense/add_edit_transaction_screen.dart';
import '../expense/expense_detail_screen.dart';
import '../income/income_detailed_screen.dart';

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

  // Helper function to get icon based on category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Icons.restaurant;
      case 'transport': return Icons.directions_car;
      case 'entertainment': return Icons.movie;
      case 'shopping': return Icons.shopping_cart;
      case 'healthcare': return Icons.local_hospital;
      case 'education': return Icons.school;
      case 'utilities': return Icons.bolt;
      case 'salary': return Icons.work;
      case 'freelance': return Icons.computer;
      case 'investment': return Icons.trending_up;
      default: return Icons.money;
    }
  }

  // Calculate monthly financial metrics from transactions
  _MonthlyFinancials _calculateMonthlyFinancials(List<TransactionModel> transactions, AppUser user) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    double totalIncome = 0;
    double totalExpenses = 0;

    for (var transaction in transactions) {
      if (transaction.month == currentMonth && transaction.year == currentYear) {
        if (transaction.type == TransactionType.income) {
          totalIncome += transaction.amount;
        } else {
          totalExpenses += transaction.amount;
        }
      }
    }

    // ✅ Use 0.0 instead of 0 to maintain double type
    final userBudget = user.monthlyBudget ?? 0.0;
    final monthlyIncome = user.monthlyIncome; // Already double, no need to convert
    final monthlySavingsGoal = user.monthlySavingsGoal ?? 0.0;

    // ✅ Default to 70% of income if no budget set
    final monthlyBudget = userBudget > 0 ? userBudget : totalIncome * 0.7;

    final actualIncome = monthlyIncome > 0 ? monthlyIncome : totalIncome;
    final actualSavings = actualIncome - totalExpenses;
    final savingsProgress = monthlySavingsGoal > 0
        ? (actualSavings / monthlySavingsGoal).clamp(0.0, 1.0)
        : 0.0;

    final budgetUsage = monthlyBudget > 0 ? (totalExpenses / monthlyBudget) : 0;

    return _MonthlyFinancials(
      income: actualIncome.toDouble(),
      expenses: totalExpenses.toDouble(),
      budget: monthlyBudget.toDouble(),
      savingsGoal: monthlySavingsGoal.toDouble(),
      savings: actualSavings.toDouble(),
      savingsProgress: savingsProgress.toDouble(),
      budgetUsage: budgetUsage.toDouble(),
    );
  }


  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authControllerProvider);
    final user = userAsync.value;
    final transactions = ref.watch(transactionProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final financials = _calculateMonthlyFinancials(transactions, user);
    final recentTransactions = transactions.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinanceAI Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
              );
            },
          ),
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

      body: RefreshIndicator(
        onRefresh: () async {
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
                  AnimatedProfileCard(user: user),
                  const SizedBox(height: 20),

                  // Budget Warning Banner
                  if (financials.budgetUsage >= 0.8)
                    _BudgetWarningBanner(
                      budgetUsage: financials.budgetUsage,
                      currency: user.currency ?? 'PKR',
                    ),

                  // Savings Goal Celebration
                  if (financials.savings >= financials.savingsGoal && financials.savingsGoal > 0)
                    _SavingsGoalCelebration(
                      currency: user.currency ?? 'PKR',
                      savings: financials.savings,
                      goal: financials.savingsGoal,
                    ),

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
                        value: '${user.currency ?? 'PKR'} ${financials.income.toStringAsFixed(2)}',
                        icon: Icons.trending_up,
                        color: Colors.green,
                        showEdit: financials.income == 0,
                        onEdit: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                          );
                        },
                      ),
                      AnimatedDashboardCard(
                        title: 'Monthly Budget',
                        value: '${user.currency ?? 'PKR'} ${financials.budget.toStringAsFixed(2)}',
                        icon: Icons.pie_chart,
                        color: Colors.blue,
                        showEdit: financials.budget == 0,
                        onEdit: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                          );
                        },
                      ),
                      AnimatedDashboardCard(
                        title: 'Monthly Expenses',
                        value: '${user.currency ?? 'PKR'} ${financials.expenses.toStringAsFixed(2)}',
                        icon: Icons.trending_down,
                        color: financials.expenses > 0 ? Colors.redAccent : Colors.grey,
                        subtitle: financials.budget > 0
                            ? '${(financials.budgetUsage * 100).toStringAsFixed(0)}% of budget'
                            : null,
                      ),
                      AnimatedDashboardCard(
                        title: 'Current Savings',
                        value: '${user.currency ?? 'PKR'} ${financials.savings.toStringAsFixed(2)}',
                        icon: Icons.savings,
                        color: financials.savings >= 0 ? Colors.teal : Colors.red,
                        subtitle: financials.savingsGoal > 0
                            ? '${(financials.savingsProgress * 100).toStringAsFixed(0)}% of goal'
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  AnimatedQuickActions(),
                  const SizedBox(height: 24),

                  if (financials.savingsGoal > 0)
                    AnimatedSavingsProgressCard(
                      currency: user.currency ?? 'PKR',
                      current: financials.savings,
                      goal: financials.savingsGoal,
                      progress: financials.savingsProgress,
                    ),

                  const SizedBox(height: 20),

                  const AnimatedSectionTitle(title: "Recent Transactions"),
                  const SizedBox(height: 12),

                  if (recentTransactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No transactions yet. Add your first transaction!"),
                    )
                  else
                    ...recentTransactions.map((transaction) =>
                        AnimatedTransactionTile(
                          icon: _getCategoryIcon(transaction.category),
                          label: transaction.category,
                          amount: '${transaction.type == TransactionType.income ? '+' : '-'}${user.currency ?? 'PKR'} ${transaction.amount.toStringAsFixed(2)}',
                          color: transaction.type == TransactionType.income ? Colors.green : Colors.red,
                        )
                    ),

                  if (transactions.isNotEmpty)
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Navigate to transactions list screen
                        },
                        child: const Text('View All Transactions'),
                      ),
                    ),

                  const SizedBox(height: 24),

                  AnimatedFinancialHealthCard(
                    income: financials.income,
                    expenses: financials.expenses,
                    budget: financials.budget,
                    savingsGoal: financials.savingsGoal,
                    savings: financials.savings,
                  ),
                  const SizedBox(height: 16),

                  if (financials.income == 0 || financials.budget == 0)
                    const AnimatedSetupPrompt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Data class for monthly financials
class _MonthlyFinancials {
  final double income;
  final double expenses;
  final double budget;
  final double savingsGoal;
  final double savings;
  final double savingsProgress;
  final double budgetUsage;

  _MonthlyFinancials({
    required this.income,
    required this.expenses,
    required this.budget,
    required this.savingsGoal,
    required this.savings,
    required this.savingsProgress,
    required this.budgetUsage,
  });
}

// Budget Warning Banner
class _BudgetWarningBanner extends StatelessWidget {
  final double budgetUsage;
  final String currency;

  const _BudgetWarningBanner({required this.budgetUsage, required this.currency});

  @override
  Widget build(BuildContext context) {
    String message;
    Color color;

    if (budgetUsage >= 1.0) {
      message = "You've exceeded your monthly budget!";
      color = Colors.red;
    } else if (budgetUsage >= 0.9) {
      message = "You've used 90% of your budget. Be careful!";
      color = Colors.orange;
    } else {
      message = "You've used ${(budgetUsage * 100).toStringAsFixed(0)}% of your budget";
      color = Colors.amber;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}

// Savings Goal Celebration
class _SavingsGoalCelebration extends StatelessWidget {
  final String currency;
  final double savings;
  final double goal;

  const _SavingsGoalCelebration({required this.currency, required this.savings, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "🎉 Congratulations! You've achieved your savings goal of $currency ${goal.toStringAsFixed(2)}",
              style: const TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}

// Update Financial Health Card to include savings
class AnimatedFinancialHealthCard extends StatelessWidget {
  final double income;
  final double expenses;
  final double budget;
  final double savingsGoal;
  final double savings;

  const AnimatedFinancialHealthCard({
    super.key,
    required this.income,
    required this.expenses,
    required this.budget,
    required this.savingsGoal,
    required this.savings,
  });

  Color _getFinancialHealthColor() {
    if (income == 0 || budget == 0) return Colors.grey;
    if (expenses > income) return Colors.red;
    if (savingsGoal > 0 && savings >= savingsGoal) return Colors.green;
    if (savings >= 0) return Colors.blue;
    return Colors.orange;
  }

  IconData _getFinancialHealthIcon() {
    if (income == 0 || budget == 0) return Icons.help;
    if (expenses > income) return Icons.warning;
    if (savingsGoal > 0 && savings >= savingsGoal) return Icons.celebration;
    if (savings >= 0) return Icons.trending_up;
    return Icons.trending_down;
  }

  String _getFinancialHealthMessage() {
    if (income == 0 || budget == 0) return "Complete your profile to see financial health analysis";
    if (expenses > income) return "Your expenses exceed your income. Consider adjusting your spending.";
    if (savingsGoal > 0 && savings >= savingsGoal) return "Great job! You've achieved your savings goal.";
    if (savingsGoal > 0) return "You're on track to meet your savings goal. Keep it up!";
    if (savings >= 0) return "Your finances look healthy. Consider setting a savings goal.";
    return "You're spending more than you earn. Review your expenses.";
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
                            name,
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
  final String? subtitle;

  const AnimatedDashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.showEdit = false,
    this.onEdit,
    this.subtitle,
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
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
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

// Update the AnimatedQuickActions to navigate to Add Transaction screen
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
        return GestureDetector(
          onTap: () {
            if (index == 0 || index == 1) {
              // Navigate to add transaction screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditTransactionScreen(),
                ),
              );
            }

            else if (index == 2 ) {
              // Navigate to add transaction screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExpenseDetailedScreen(),
                ),
              );
            }

            else if (index == 3 ) {
              // Navigate to add transaction screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IncomeDetailedScreen(),
                ),
              );
            }

          },

          child: Column(
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
          ),
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
          elevation: 4,
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
                          value: value,
                          strokeWidth: 10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            value >= 1.0 ? Colors.green : Colors.blue,
                          ),
                          backgroundColor: Colors.grey.shade300,
                        ),
                      ),
                      Text(
                        "${(value * 100).toStringAsFixed(0)}%",
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