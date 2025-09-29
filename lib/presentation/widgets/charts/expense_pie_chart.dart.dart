// lib/presentation/screens/dashboard/widgets/expense_pie_chart.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/utils/chart_utils.dart';
import '../../../state/chart_provider.dart';

class ExpensePieChart extends ConsumerStatefulWidget {
  const ExpensePieChart({super.key});

  @override
  ConsumerState<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends ConsumerState<ExpensePieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  int? _touchedIndex;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
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
    final chartDataAsync = ref.watch(chartDataProvider);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildChartContent(chartDataAsync),
          ),
        );
      },
    );
  }

  Widget _buildChartContent(AsyncValue<ChartData> chartDataAsync) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: Colors.blue.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.pie_chart,
                        color: Colors.red.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Expense Distribution',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Breakdown by category',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                chartDataAsync.when(
                  data: (chartData) {
                    if (chartData.expenseByCategory.isEmpty) {
                      return const _EmptyChartPlaceholder(
                        message: 'No expenses recorded yet',
                        subtitle: 'Add expenses to see category breakdown',
                      );
                    }
                    return _buildChartWithData(chartData.expenseByCategory);
                  },
                  loading: () => _buildLoadingState(),
                  error: (error, stack) => _buildErrorState(error.toString()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartWithData(Map<String, double> categoryData) {
    final total = categoryData.values.fold(0.0, (sum, amount) => sum + amount);
    final sortedData = _sortCategoriesByAmount(categoryData);

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Row(
            children: [
              // Pie Chart
              Expanded(
                flex: 2,
                child: MouseRegion(
                  onHover: (event) {},
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: _buildPieSections(sortedData, total),
                      startDegreeOffset: 180,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Legend
              Expanded(
                flex: 3,
                child: _buildEnhancedLegend(sortedData, total),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Total Expenses
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Expenses',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                'PKR ${total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(List<MapEntry<String, double>> sortedData, double total) {
    return sortedData.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final amount = entry.value.value;
      final percentage = (amount / total * 100);

      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 50.0 : 40.0;
      final color = ChartColors.pieColors[index % ChartColors.pieColors.length];

      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        badgeWidget: isTouched ? _buildBadge(category, amount) : null,
        badgePositionPercentageOffset: 0.98,
      );
    }).toList();
  }

  Widget _buildBadge(String category, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEnhancedLegend(List<MapEntry<String, double>> sortedData, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: sortedData.length,
            itemBuilder: (context, index) {
              final entry = sortedData[index];
              final percentage = (entry.value / total * 100);
              final color = ChartColors.pieColors[index % ChartColors.pieColors.length];

              return _buildLegendItem(
                entry.key,
                entry.value,
                percentage,
                color,
                index == _touchedIndex,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String category, double amount, double percentage, Color color, bool isHighlighted) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Category name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isHighlighted ? color : Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount
          Text(
            'PKR ${amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, double>> _sortCategoriesByAmount(Map<String, double> categoryData) {
    final entries = categoryData.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade600),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading expenses...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load chart',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChartPlaceholder extends StatelessWidget {
  final String message;
  final String subtitle;

  const _EmptyChartPlaceholder({
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
