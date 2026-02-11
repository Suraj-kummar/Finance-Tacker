import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:project_track_your_finance/screens/groups_screen.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';
import 'analytics_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import '../utils/pdf_export.dart';
import '../utils/wallet_pdf_export.dart';
import 'package:project_track_your_finance/screens/calculator_screen.dart';
import 'help_support_screen.dart';
import '../modules/statement_import/screens/import_dashboard_screen.dart';
import 'about_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedCategory = 'All';
  String _filterType = 'All'; // All, Today, Week, Month, Year, Custom
  DateTime? _startDate;
  DateTime? _endDate;
  final ScrollController _scrollController = ScrollController();

  Future<void> _exportToPDF(BuildContext context) async {
    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      final transactions = provider.transactions;
      final income = transactions.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
      final expenses = transactions.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
      final balance = income - expenses;
      
      await WalletPdfExporter.exportTransactions(
        transactions: transactions,
        totalIncome: income,
        totalExpenses: expenses,
        balance: balance,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // M3 ColorScheme
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: Colors.black.withOpacity(0.05),
            title: Row(
              children: [
                Text(
                  "Finance Tracker",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    "PRO",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            actions: const [],
          ),
          
          SliverToBoxAdapter(
            child: Consumer<TransactionProvider>(
              // ... existing builder ...
              builder: (context, transactionProvider, child) {
                // Apply category and date filters
                var transactions = transactionProvider.transactions
                    .where((t) => _selectedCategory == 'All' || t.category == _selectedCategory)
                    .toList();
                
                // Apply date range filter
                if (_startDate != null && _endDate != null) {
                  transactions = transactions.where((t) {
                    return t.date.isAfter(_startDate!.subtract(const Duration(seconds: 1))) &&
                           t.date.isBefore(_endDate!.add(const Duration(seconds: 1)));
                  }).toList();
                }

                final double totalIncome = transactions.where((t) => t.isIncome).fold(0, (sum, t) => sum + t.amount);
                final double totalExpenses = transactions.where((t) => !t.isIncome).fold(0, (sum, t) => sum + t.amount);
                final double balance = totalIncome - totalExpenses;

                return Column(
                  children: [
                    // Enhanced Spending Summary Card
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                           colors: [
                             colorScheme.primary, 
                             colorScheme.primary.withOpacity(0.7),
                           ], 
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                           BoxShadow(
                             color: colorScheme.primary.withOpacity(0.4), 
                             blurRadius: 24, 
                             offset: const Offset(0, 12),
                             spreadRadius: 2,
                           ),
                           BoxShadow(
                             color: Colors.black.withOpacity(0.1), 
                             blurRadius: 8, 
                             offset: const Offset(0, 4),
                           ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            // Decorative circles
                            Positioned(
                              top: -50,
                              right: -50,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -30,
                              left: -30,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                            ),
                            
                            // Watermark
                            Positioned(
                              bottom: 12,
                              right: 16,
                              child: Transform.rotate(
                                angle: -0.05,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Finance Tracker',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white.withOpacity(0.12),
                                        letterSpacing: 1.5,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'PRO',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white.withOpacity(0.15),
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.25),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_wallet_rounded, 
                                          color: Colors.white, 
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Total Balance", 
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.95), 
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "₹${balance.toStringAsFixed(2)}", 
                                    style: const TextStyle(
                                      color: Colors.white, 
                                      fontSize: 40, 
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildSummaryItem(
                                          context, 
                                          "Income", 
                                          totalIncome, 
                                          Icons.arrow_downward_rounded, 
                                          Colors.white,
                                        ),
                                      ),
                                      Container(
                                        width: 1, 
                                        height: 50, 
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                      Expanded(
                                        child: _buildSummaryItem(
                                          context, 
                                          "Expense", 
                                          totalExpenses, 
                                          Icons.arrow_upward_rounded, 
                                          Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Quick Actions Row (Real Features)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                           GestureDetector(
                             onTap: _showFilterOptions,
                             child: _buildQuickAction(
                               context, 
                               Icons.filter_list_rounded, 
                               "Filter",
                               [const Color(0xFF007AFF), const Color(0xFF3395FF)], // Blue
                             ),
                           ),
                           GestureDetector(
                             onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => const ImportDashboardScreen()));
                             },
                             child: _buildQuickAction(
                               context, 
                               Icons.file_upload_outlined, 
                               "Import",
                               [const Color(0xFF34C759), const Color(0xFFb0e4b9)], // Green
                             ),
                           ),
                           GestureDetector(
                             onTap: () {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(builder: (context) => const SettingsScreen()),
                               );
                             },
                             child: _buildQuickAction(
                               context, 
                               Icons.settings_rounded, 
                               "Settings",
                               [const Color(0xFF8E8E93), const Color(0xFFAEB0B6)], // Metal Grey
                             ),
                           ),
                           GestureDetector(
                              onTap: () {
                                // Show More Menu
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Handle bar
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 24),
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        // App Grid
                                        Wrap(
                                          spacing: 24,
                                          runSpacing: 24,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            _buildIOSAppIcon(
                                              context,
                                              title: "Calculator",
                                              icon: Icons.calculate_rounded,
                                              gradientColors: [const Color(0xFFFF9F0A), const Color(0xFFFFB340)],
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => const CalculatorScreen()));
                                              },
                                            ),
                                            _buildIOSAppIcon(
                                              context,
                                              title: "Help",
                                              icon: Icons.help_outline_rounded,
                                              gradientColors: [const Color(0xFF0A84FF), const Color(0xFF409CFF)],
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
                                              },
                                            ),
                                            _buildIOSAppIcon(
                                              context,
                                              title: "Export",
                                              icon: Icons.file_download_outlined,
                                              gradientColors: [const Color(0xFF5E5CE6), const Color(0xFF7D7AFF)], // iOS Purple/Blue
                                              onTap: () {
                                                Navigator.pop(context);
                                                _exportToPDF(context);
                                              },
                                            ),
                                            _buildIOSAppIcon(
                                              context,
                                              title: "About",
                                              icon: Icons.info_outline_rounded,
                                              gradientColors: [const Color(0xFF8E8E93), const Color(0xFFAEB0B6)],
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: _buildQuickAction(
                                context, 
                                Icons.more_horiz_rounded, 
                                "More",
                                [const Color(0xFF545456), const Color(0xFF6C6C70)], // Dark Grey
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 24),

                    // Section Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Transactions',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Filter Chip Display (if active)
                    if (_selectedCategory != 'All')
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Chip(
                                label: Text("Category: $_selectedCategory"),
                                onDeleted: () => setState(() => _selectedCategory = 'All'),
                                deleteIcon: const Icon(Icons.close, size: 18),
                            ),
                        ),
                  ],
                );
              },
            ),
          ),
          
          // Transaction List
          Consumer<TransactionProvider>(
            builder: (context, transactionProvider, child) {
              final transactions = transactionProvider.transactions
                  .where((t) => _selectedCategory == 'All' || t.category == _selectedCategory)
                  .toList();
              
              if (transactions.isEmpty) {
                 return SliverFillRemaining(
                   hasScrollBody: false,
                   child: Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Container(
                           padding: const EdgeInsets.all(24),
                           decoration: BoxDecoration(
                             gradient: LinearGradient(
                               colors: [
                                 colorScheme.primary.withOpacity(0.1),
                                 colorScheme.primary.withOpacity(0.05),
                               ],
                             ),
                             shape: BoxShape.circle,
                           ),
                           child: Icon(
                             Icons.receipt_long_rounded, 
                             size: 80, 
                             color: colorScheme.primary.withOpacity(0.5),
                           ),
                         ),
                         const SizedBox(height: 24),
                         Text(
                           "No transactions yet",
                           style: textTheme.titleLarge?.copyWith(
                             fontWeight: FontWeight.bold,
                             color: colorScheme.onSurface,
                           ),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           "Tap the + button to add your first transaction",
                           style: textTheme.bodyMedium?.copyWith(
                             color: colorScheme.onSurfaceVariant,
                           ),
                           textAlign: TextAlign.center,
                         ),
                       ],
                     ),
                   ),
                 );
              }

              // Sort by date (newest first)
              transactions.sort((a, b) => b.date.compareTo(a.date));

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final transaction = transactions[index];
                    return _buildTransactionTile(transaction, context)
                        .animate(delay: (50 * index).ms) // Staggered animation
                        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                        .slideX(begin: 0.1, duration: 300.ms, curve: Curves.easeOut);
                  },
                  childCount: transactions.length,
                ),
              );
            },
          ),
          // Add some bottom padding for the FAB
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, double amount, IconData icon, Color iconColor) {
     return Padding(
       padding: const EdgeInsets.symmetric(horizontal: 8),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             children: [
               Container(
                 padding: const EdgeInsets.all(4),
                 decoration: BoxDecoration(
                   color: Colors.white.withOpacity(0.2),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(icon, color: iconColor, size: 16),
               ),
               const SizedBox(width: 8),
               Text(
                 label, 
                 style: TextStyle(
                   color: Colors.white.withOpacity(0.8), 
                   fontSize: 13,
                   fontWeight: FontWeight.w500,
                 ),
               ),
             ],
           ),
           const SizedBox(height: 8),
           Text(
             "₹${amount.toStringAsFixed(2)}", 
             style: const TextStyle(
               color: Colors.white, 
               fontSize: 18, 
               fontWeight: FontWeight.w700,
             ),
           ),
         ],
       ),
     );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, List<Color> colors) {
     final colorScheme = Theme.of(context).colorScheme;
     
     return Column(
       children: [
         Container(
           height: 60,
           width: 60,
           decoration: BoxDecoration(
             gradient: LinearGradient(
               colors: colors,
               begin: Alignment.topLeft,
               end: Alignment.bottomRight,
             ),
             borderRadius: BorderRadius.circular(18),
             boxShadow: [
               BoxShadow(
                 color: colors[0].withOpacity(0.4),
                 blurRadius: 10,
                 offset: const Offset(0, 4),
               ),
             ],
           ),
           child: Stack(
             children: [
               // Gloss Shine
               Positioned(
                 top: 0, left: 0, right: 0, height: 30,
                 child: Container(
                   decoration: BoxDecoration(
                     gradient: LinearGradient(
                       colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.0)],
                       begin: Alignment.topCenter,
                       end: Alignment.bottomCenter,
                     ),
                     borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                   ),
                   child: null,
                 ),
               ),
               // Icon
               Center(
                 child: Icon(
                   icon, 
                   color: Colors.white,
                   size: 26,
                   shadows: [Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                 ),
               ),
             ],
           ),
         ),
         const SizedBox(height: 8),
         Text(
           label, 
           style: TextStyle(
             fontSize: 12, 
             fontWeight: FontWeight.w600, 
             color: colorScheme.onSurface.withOpacity(0.8),
           ),
         ),
       ],
     );
  }

    Widget _buildIOSAppIcon(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16), // IOS squircle-like
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Gloss effect (Top shine)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  ),
                ),
                // Icon
                Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildTransactionTile(Transaction transaction, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIncome = transaction.isIncome;
    final amountColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final icon = isIncome ? Icons.trending_down_rounded : Icons.trending_up_rounded;
    final iconBg = isIncome ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1);

    return Dismissible(
      key: Key(transaction.id.toString()),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 28),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Transaction"),
            content: const Text("Are you sure you want to delete this transaction?"),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true), 
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
         Provider.of<TransactionProvider>(context, listen: false).deleteTransaction(transaction.id!);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUpdateTransactionSheet(context, transaction),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          amountColor.withOpacity(0.15),
                          amountColor.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: amountColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: amountColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                transaction.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today_rounded, size: 13, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd').format(transaction.date),
                              style: TextStyle(
                                fontSize: 12, 
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          '${isIncome ? '+' : '-'} ₹${transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: amountColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            letterSpacing: -0.5,
                          ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          DateFormat('h:mm a').format(transaction.date),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Transactions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Date Range Filter
              const Text('Time Period', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('All', _filterType == 'All', () {
                    setModalState(() => _filterType = 'All');
                    setState(() {
                      _filterType = 'All';
                      _startDate = null;
                      _endDate = null;
                    });
                  }),
                  _buildFilterChip('Today', _filterType == 'Today', () {
                    final now = DateTime.now();
                    setModalState(() => _filterType = 'Today');
                    setState(() {
                      _filterType = 'Today';
                      _startDate = DateTime(now.year, now.month, now.day);
                      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                    });
                  }),
                  _buildFilterChip('This Week', _filterType == 'Week', () {
                    final now = DateTime.now();
                    final weekStart = now.subtract(Duration(days: now.weekday - 1));
                    setModalState(() => _filterType = 'Week');
                    setState(() {
                      _filterType = 'Week';
                      _startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
                      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                    });
                  }),
                  _buildFilterChip('This Month', _filterType == 'Month', () {
                    final now = DateTime.now();
                    setModalState(() => _filterType = 'Month');
                    setState(() {
                      _filterType = 'Month';
                      _startDate = DateTime(now.year, now.month, 1);
                      _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                    });
                  }),
                  _buildFilterChip('This Year', _filterType == 'Year', () {
                    final now = DateTime.now();
                    setModalState(() => _filterType = 'Year');
                    setState(() {
                      _filterType = 'Year';
                      _startDate = DateTime(now.year, 1, 1);
                      _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
                    });
                  }),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Category Filter
              const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'All', 'Food', 'Transport', 'Shopping', 'Entertainment', 
                  'Bills', 'Health', 'Education', 'Other'
                ].map((category) => _buildFilterChip(
                  category,
                  _selectedCategory == category,
                  () {
                    setModalState(() => _selectedCategory = category);
                    setState(() => _selectedCategory = category);
                  },
                )).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Apply Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply Filters'),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showUpdateTransactionSheet(BuildContext context, Transaction transaction) {
    // Navigate to update screen or show modal
    // For simplicity, reusing the logic but with M3 BottomSheet
     TextEditingController nameController = TextEditingController(text: transaction.name);
     TextEditingController amountController = TextEditingController(text: transaction.amount.toString());
     // ... logic can be similar to AddTransactionScreen but populated
     // For now, let's just use a simple sheet for demo
     showModalBottomSheet(
       context: context,
       isScrollControlled: true,
       showDragHandle: true,
       builder: (ctx) => Padding(
         padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
             const SizedBox(height: 12),
             TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()), keyboardType: TextInputType.number),
             const SizedBox(height: 24),
              FilledButton(
               onPressed: () {
                 final updated = transaction.copyWith(
                   name: nameController.text,
                   amount: double.parse(amountController.text),
                 );
                 Provider.of<TransactionProvider>(context, listen: false).updateTransaction(updated);
                 Navigator.pop(context);
               },
               child: const Text('Update Transaction'),
             ),
             const SizedBox(height: 24),
           ],
         ),
       ),
     );
  }
}