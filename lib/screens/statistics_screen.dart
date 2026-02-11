import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'All Time';
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: Colors.black.withOpacity(0.05),
            title: Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                final transactions = provider.transactions;
                final income = transactions.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
                final expenses = transactions.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
                final balance = income - expenses;
                
                // Category breakdown
                final Map<String, double> categoryExpenses = {};
                for (var t in transactions.where((t) => !t.isIncome)) {
                  categoryExpenses[t.category] = (categoryExpenses[t.category] ?? 0) + t.amount;
                }
                final sortedCategories = categoryExpenses.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards
                      _buildSummaryCards(income, expenses, balance, colorScheme, isDark),
                      
                      const SizedBox(height: 24),
                      
                      // Insights & Analytics
                      _buildInsightsSection(income, expenses, balance, transactions, colorScheme, isDark),
                      
                      const SizedBox(height: 24),
                      
                      // Quick Stats
                      _buildQuickStats(transactions, colorScheme, isDark),
                      
                      const SizedBox(height: 24),
                      
                      // Pie Chart
                      if (categoryExpenses.isNotEmpty)
                        _buildCategoryPieChart(sortedCategories, colorScheme, isDark),
                      
                      const SizedBox(height: 24),
                      
                      // Category Breakdown List
                      if (categoryExpenses.isNotEmpty)
                        _buildCategoryBreakdown(sortedCategories, expenses, colorScheme, isDark),
                      
                      const SizedBox(height: 24),
                      
                      // Monthly Trend
                      _buildMonthlyTrend(transactions, colorScheme, isDark),
                      
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCards(double income, double expenses, double balance, ColorScheme colorScheme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Income',
            income,
            Icons.trending_up_rounded,
            const Color(0xFF10B981),
            colorScheme,
            isDark,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Expenses',
            expenses,
            Icons.trending_down_rounded,
            const Color(0xFFEF4444),
            colorScheme,
            isDark,
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Balance',
            balance,
            Icons.account_balance_wallet_rounded,
            balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            colorScheme,
            isDark,
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCard(String label, double amount, IconData icon, Color accentColor, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF252525)]
              : [Colors.white, colorScheme.surfaceContainer.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rs.${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsightsSection(double income, double expenses, double balance, List<Transaction> transactions, ColorScheme colorScheme, bool isDark) {
    final savingsRate = income > 0 ? ((income - expenses) / income * 100) : 0;
    final spendingRate = income > 0 ? (expenses / income * 100) : 0;
    
    String financialHealth = 'Excellent';
    Color healthColor = const Color(0xFF10B981);
    IconData healthIcon = Icons.trending_up_rounded;
    
    if (savingsRate < 10) {
      financialHealth = 'Needs Attention';
      healthColor = const Color(0xFFEF4444);
      healthIcon = Icons.warning_rounded;
    } else if (savingsRate < 20) {
      financialHealth = 'Fair';
      healthColor = const Color(0xFFF59E0B);
      healthIcon = Icons.trending_flat_rounded;
    } else if (savingsRate < 30) {
      financialHealth = 'Good';
      healthColor = const Color(0xFF3B82F6);
      healthIcon = Icons.thumb_up_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF252525)]
              : [Colors.white, colorScheme.surfaceContainer.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: healthColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: healthColor.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [healthColor, healthColor.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: healthColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(healthIcon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Health',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      financialHealth,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: healthColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Savings Rate
          _buildInsightMetric(
            'Savings Rate',
            '${savingsRate.toStringAsFixed(1)}%',
            savingsRate / 100,
            'You save ${savingsRate.toStringAsFixed(0)}% of your income',
            healthColor,
            colorScheme,
          ),
          const SizedBox(height: 16),
          
          // Spending Rate
          _buildInsightMetric(
            'Spending Rate',
            '${spendingRate.toStringAsFixed(1)}%',
            spendingRate > 100 ? 1.0 : spendingRate / 100,
            'You spend ${spendingRate.toStringAsFixed(0)}% of your income',
            spendingRate > 80 ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
            colorScheme,
          ),
          
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: healthColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: healthColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: healthColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    savingsRate >= 20 
                        ? 'Great job! You\'re saving well. Keep it up!'
                        : savingsRate >= 10
                            ? 'Try to increase your savings by reducing non-essential expenses.'
                            : 'Consider reviewing your expenses to improve savings.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, duration: 500.ms);
  }
  
  Widget _buildInsightMetric(String label, String value, double progress, String description, Color color, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: colorScheme.surfaceContainer,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickStats(List<Transaction> transactions, ColorScheme colorScheme, bool isDark) {
    final incomeTransactions = transactions.where((t) => t.isIncome).toList();
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    
    final avgIncome = incomeTransactions.isNotEmpty
        ? incomeTransactions.fold(0.0, (sum, t) => sum + t.amount) / incomeTransactions.length
        : 0;
    final avgExpense = expenseTransactions.isNotEmpty
        ? expenseTransactions.fold(0.0, (sum, t) => sum + t.amount) / expenseTransactions.length
        : 0;
    
    // Find largest transaction
    final largestExpense = expenseTransactions.isNotEmpty
        ? expenseTransactions.reduce((a, b) => a.amount > b.amount ? a : b)
        : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Insights',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickStatCard(
                'Total Transactions',
                transactions.length.toString(),
                Icons.receipt_long_rounded,
                const Color(0xFF667eea),
                colorScheme,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStatCard(
                'Avg. Income',
                'Rs.${avgIncome.toStringAsFixed(0)}',
                Icons.arrow_downward_rounded,
                const Color(0xFF10B981),
                colorScheme,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickStatCard(
                'Avg. Expense',
                'Rs.${avgExpense.toStringAsFixed(0)}',
                Icons.arrow_upward_rounded,
                const Color(0xFFEF4444),
                colorScheme,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStatCard(
                'Largest Expense',
                largestExpense != null ? 'Rs.${largestExpense.amount.toStringAsFixed(0)}' : 'Rs.0',
                Icons.trending_up_rounded,
                const Color(0xFFF59E0B),
                colorScheme,
                isDark,
              ),
            ),
          ],
        ),
        if (largestExpense != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1E1E1E), const Color(0xFF252525)]
                    : [Colors.white, colorScheme.surfaceContainer.withOpacity(0.3)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biggest Expense',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${largestExpense.name} - ${largestExpense.category}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(largestExpense.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildQuickStatCard(String label, String value, IconData icon, Color color, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF252525)]
              : [Colors.white, colorScheme.surfaceContainer.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), duration: 400.ms);
  }
  
  Widget _buildCategoryPieChart(List<MapEntry<String, double>> categories, ColorScheme colorScheme, bool isDark) {
    final colors = [
      const Color(0xFF667eea),
      const Color(0xFFf093fb),
      const Color(0xFF4facfe),
      const Color(0xFF43e97b),
      const Color(0xFFfa709a),
      const Color(0xFFfee140),
    ];
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF252525)]
              : [Colors.white, colorScheme.surfaceContainer.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: categories.take(6).toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value;
                        return PieChartSectionData(
                          value: category.value,
                          title: '${(category.value / categories.fold(0.0, (sum, e) => sum + e.value) * 100).toStringAsFixed(0)}%',
                          color: colors[index % colors.length],
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categories.take(6).toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category.key,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms).scale(begin: const Offset(0.95, 0.95), duration: 500.ms);
  }
  
  Widget _buildCategoryBreakdown(List<MapEntry<String, double>> categories, double totalExpenses, ColorScheme colorScheme, bool isDark) {
    final colors = [
      const Color(0xFF667eea),
      const Color(0xFFf093fb),
      const Color(0xFF4facfe),
      const Color(0xFF43e97b),
      const Color(0xFFfa709a),
      const Color(0xFFfee140),
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Categories',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...categories.take(6).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final percentage = (category.value / totalExpenses * 100);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1E1E1E), const Color(0xFF252525)]
                    : [Colors.white, colorScheme.surfaceContainer.withOpacity(0.3)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors[index % colors.length].withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors[index % colors.length].withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCategoryIcon(category.key),
                        color: colors[index % colors.length],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.key,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}% of total',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs.${category.value.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors[index % colors.length],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: colorScheme.surfaceContainer,
                    valueColor: AlwaysStoppedAnimation(colors[index % colors.length]),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ).animate(delay: (100 * index).ms)
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.1, duration: 400.ms);
        }).toList(),
      ],
    );
  }
  
  Widget _buildMonthlyTrend(List<Transaction> transactions, ColorScheme colorScheme, bool isDark) {
    // Get last 6 months data
    final now = DateTime.now();
    final monthlyData = <String, Map<String, double>>{};
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM').format(month);
      monthlyData[monthKey] = {'income': 0, 'expense': 0};
    }
    
    for (var t in transactions) {
      final monthKey = DateFormat('MMM').format(t.date);
      if (monthlyData.containsKey(monthKey)) {
        if (t.isIncome) {
          monthlyData[monthKey]!['income'] = (monthlyData[monthKey]!['income'] ?? 0) + t.amount;
        } else {
          monthlyData[monthKey]!['expense'] = (monthlyData[monthKey]!['expense'] ?? 0) + t.amount;
        }
      }
    }
    
    final maxValue = monthlyData.values.fold(0.0, (max, data) {
      final monthMax = [data['income'] ?? 0, data['expense'] ?? 0].reduce((a, b) => a > b ? a : b);
      return monthMax > max ? monthMax : max;
    });
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF252525)]
              : [Colors.white, colorScheme.surfaceContainer.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Trend',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue > 0 ? maxValue * 1.2 : 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final months = monthlyData.keys.toList();
                        if (value.toInt() >= 0 && value.toInt() < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              months[value.toInt()],
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue > 0 ? maxValue / 4 : 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colorScheme.outlineVariant.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: monthlyData.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data['income'] ?? 0,
                        color: const Color(0xFF10B981),
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: data['expense'] ?? 0,
                        color: const Color(0xFFEF4444),
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Income', const Color(0xFF10B981)),
              const SizedBox(width: 24),
              _buildLegend('Expenses', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95), duration: 500.ms);
  }
  
  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant_rounded;
      case 'Transport': return Icons.directions_car_rounded;
      case 'Shopping': return Icons.shopping_bag_rounded;
      case 'Entertainment': return Icons.movie_rounded;
      case 'Utilities': return Icons.lightbulb_rounded;
      case 'Rent': return Icons.home_rounded;
      case 'Travel': return Icons.flight_rounded;
      case 'Health': return Icons.local_hospital_rounded;
      default: return Icons.more_horiz_rounded;
    }
  }
}