import 'package:flutter/material.dart';

class ExpenseTrackerCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  final double balance;

  const ExpenseTrackerCard({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      shadowColor: Colors.transparent, // M3 style (filled or outlined usually, or subtle shadow)
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Financial Overview",
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Balance Display
            Center(
              child: _buildInfo(
                context,
                "Balance",
                balance,
                colorScheme.onPrimaryContainer,
                36, // Large headline
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // Income & Expenses Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfo(
                  context,
                  "Income",
                  totalIncome,
                  const Color(0xFF00C853), // Custom Green for contrast on container
                  20,
                  FontWeight.w600,
                  icon: Icons.arrow_downward_rounded,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: colorScheme.onPrimaryContainer.withOpacity(0.2),
                ),
                _buildInfo(
                  context,
                  "Expenses",
                  totalExpenses,
                  colorScheme.error,
                  20,
                  FontWeight.w600,
                  icon: Icons.arrow_upward_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, String label, double amount,
      Color color, double fontSize, FontWeight fontWeight, {IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              "₹${amount.toStringAsFixed(2)}",
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: fontWeight,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onPrimaryContainer.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
