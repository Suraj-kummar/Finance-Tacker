import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/group.dart';
import '../models/transaction.dart';
import 'add_group_transaction_screen.dart';
import '../l10n/app_localizations.dart';
import '../utils/group_pdf_export.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Group group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Transaction> _groupTransactions = [];
  Map<String, double> _balances = {};
  bool _isLoading = true;
  String? _error;
  
  // Summary Stats
  double _totalCost = 0;
  double _myContribution = 0;
  double _myShare = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.group.id != null) {
      _loadGroupData();
    } else {
      _isLoading = false;
      _error = "Invalid Group ID";
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupData() async {
    if (widget.group.id == null) return;
    
    setState(() => _isLoading = true);
    setState(() => _error = null);

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final transactions = await context.read<GroupProvider>().getGroupTransactions(widget.group.id!);

      if (mounted) {
        setState(() {
          _groupTransactions = transactions;
          _calculateBalances();
          _calculateStats();
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load group data. Please try again.';
        });
      }
    }
  }

  void _calculateStats() {
    double total = 0;
    double myContrib = 0;
    double myShare = 0;

    for (var t in _groupTransactions) {
      if (t.isSettlement) continue; 

      total += t.amount;
      if (t.paidBy == 'You') {
        myContrib += t.amount;
      }
      
      if (t.split != null) {
        if (t.split!.containsKey('You')) {
            var share = t.split!['You'];
            if (share is num) myShare += share.toDouble();
        }
      }
    }

    _totalCost = total;
    _myContribution = myContrib;
    _myShare = myShare;
  }

  void _calculateBalances() {
    final Map<String, double> balances = {};

    for (var member in widget.group.members) {
      if (member.trim().isNotEmpty) {
        balances[member.trim()] = 0.0;
      }
    }
    
    if (!balances.containsKey('You')) {
      balances['You'] = 0.0;
    }

    for (var transaction in _groupTransactions) {
      try {
        if (transaction.split != null &&
            transaction.paidBy != null &&
            transaction.paidBy!.trim().isNotEmpty) {
          final paidBy = transaction.paidBy!.trim();

          balances[paidBy] = (balances[paidBy] ?? 0) + transaction.amount;

          transaction.split!.forEach((member, owedAmount) {
            final memberKey = member.trim();
            if (memberKey.isNotEmpty && owedAmount > 0) {
              balances[memberKey] = (balances[memberKey] ?? 0) - owedAmount;
            }
          });
        }
      } catch (e) {
        debugPrint('Error calculating balance: $e');
      }
    }

    _balances = balances;
  }

  Future<void> _navigateToAddGroupTransaction({Transaction? transactionToEdit}) async {
    HapticFeedback.lightImpact();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddGroupTransactionScreen(
            group: widget.group,
            transactionToEdit: transactionToEdit,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      await _loadGroupData();
    }
  }

  Future<void> _settleUp(String debtor, String creditor, double amount) async {
    // Basic Settle Up implementation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settle Up'),
        content: Text('Mark ${debtor == 'You' ? 'your' : "$debtor's"} debt of ₹${amount.toStringAsFixed(2)} to ${creditor == 'You' ? 'you' : creditor} as paid?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('Confirm')),
        ],
      ),
    );

    if (confirm == true) {
      final transaction = Transaction(
        name: 'Settlement to $creditor',
        amount: amount,
        isIncome: false,
        category: 'Transfer',
        date: DateTime.now(),
        groupId: widget.group.id,
        paidBy: debtor,
        split: {creditor: amount},
        isSettlement: true,
      );

      await context.read<TransactionProvider>().addTransaction(transaction);
      _loadGroupData();
    }
  }

 Future<void> _deleteTransaction(Transaction transaction) async {
    try {
      await context.read<TransactionProvider>().deleteTransaction(transaction.id!);
      if (mounted) {
        await _loadGroupData();
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.transactionDeletedSuccessfully)),
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  String _getTypeLabel() {
      switch (widget.group.type) {
          case 'trip': return 'Trip';
          case 'home': return 'Home';
          case 'couple': return 'Couple';
          default: return 'Group';
      }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.name, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
               _getTypeLabel(), 
               style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Expenses'),
            Tab(text: 'Info'),
          ],
        ),
        actions: [
            IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded),
                tooltip: 'Export to PDF',
                onPressed: () async {
                  try {
                    await GroupPdfExporter.exportGroupTransactions(
                      group: widget.group,
                      transactions: _groupTransactions,
                      totalCost: _totalCost,
                      myShare: _myShare,
                      myContribution: _myContribution,
                      balances: _balances,
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to export PDF: $e')),
                      );
                    }
                  }
                },
            ),
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadGroupData,
            )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildExpensesTab(),
            _buildInfoTab(),
          ],
        ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'group_details_fab',
        onPressed: () => _navigateToAddGroupTransaction(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 24),
          
          Text("Balances", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildBalancesList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
     final colorScheme = Theme.of(context).colorScheme;
     final isDark = Theme.of(context).brightness == Brightness.dark;
     final label = widget.group.type == 'trip' ? "Trip Expenses" : "Total Expenses";
     
     // Calculate category breakdown
     final Map<String, double> categoryTotals = {};
     for (var t in _groupTransactions) {
       if (!t.isSettlement) {
         categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
       }
     }
     final topCategories = categoryTotals.entries.toList()
       ..sort((a, b) => b.value.compareTo(a.value));
     
     return Container(
       decoration: BoxDecoration(
         gradient: LinearGradient(
           colors: isDark
               ? [colorScheme.primary.withOpacity(0.2), colorScheme.primary.withOpacity(0.1)]
               : [colorScheme.primary, colorScheme.primary.withOpacity(0.85)],
           begin: Alignment.topLeft,
           end: Alignment.bottomRight,
         ),
         borderRadius: BorderRadius.circular(24),
         boxShadow: [
           BoxShadow(
             color: colorScheme.primary.withOpacity(0.3),
             blurRadius: 20,
             offset: const Offset(0, 8),
             spreadRadius: -4,
           )
         ]
       ),
       child: ClipRRect(
         borderRadius: BorderRadius.circular(24),
         child: Stack(
           children: [
             // Decorative elements
             Positioned(
               right: -40,
               top: -40,
               child: Container(
                 width: 150,
                 height: 150,
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   color: Colors.white.withOpacity(isDark ? 0.03 : 0.1),
                 ),
               ),
             ),
             Positioned(
               left: -20,
               bottom: -20,
               child: Container(
                 width: 100,
                 height: 100,
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   color: Colors.white.withOpacity(isDark ? 0.02 : 0.05),
                 ),
               ),
             ),
             // Content
             Padding(
               padding: const EdgeInsets.all(24),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   // Header
                   Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(10),
                         decoration: BoxDecoration(
                           color: Colors.white.withOpacity(isDark ? 0.1 : 0.2),
                           shape: BoxShape.circle,
                         ),
                         child: Icon(
                           widget.group.type == 'home' ? Icons.home_rounded : 
                           widget.group.type == 'couple' ? Icons.favorite_rounded :
                           Icons.flight_takeoff_rounded,
                           color: isDark ? colorScheme.primary : Colors.white,
                           size: 24,
                         ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               label,
                               style: TextStyle(
                                 color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.white.withOpacity(0.9),
                                 fontSize: 13,
                                 fontWeight: FontWeight.w600,
                                 letterSpacing: 0.5,
                               ),
                             ),
                             const SizedBox(height: 4),
                             Text(
                               "${_groupTransactions.where((t) => !t.isSettlement).length} transactions",
                               style: TextStyle(
                                 color: isDark ? colorScheme.onSurface.withOpacity(0.5) : Colors.white.withOpacity(0.7),
                                 fontSize: 11,
                               ),
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 20),
                   
                   // Total Amount
                   Text(
                     "₹${_totalCost.toStringAsFixed(2)}",
                     style: TextStyle(
                       color: isDark ? colorScheme.primary : Colors.white,
                       fontSize: 40,
                       fontWeight: FontWeight.w800,
                       letterSpacing: -1.5,
                       height: 1,
                     ),
                   ),
                   const SizedBox(height: 24),
                   
                   // Your Stats
                   Row(
                     children: [
                       Expanded(
                         child: _buildStatItem(
                           "Your Share",
                           "₹${_myShare.toStringAsFixed(0)}",
                           Icons.pie_chart_outline_rounded,
                           isDark,
                           colorScheme,
                         ),
                       ),
                       Container(
                         width: 1,
                         height: 50,
                         color: isDark ? colorScheme.onSurface.withOpacity(0.1) : Colors.white.withOpacity(0.2),
                       ),
                       Expanded(
                         child: _buildStatItem(
                           "You Paid",
                           "₹${_myContribution.toStringAsFixed(0)}",
                           Icons.account_balance_wallet_outlined,
                           isDark,
                           colorScheme,
                         ),
                       ),
                     ],
                   ),
                   
                   // Top Categories
                   if (topCategories.isNotEmpty) const SizedBox(height: 20),
                   if (topCategories.isNotEmpty)
                     Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Colors.white.withOpacity(isDark ? 0.05 : 0.15),
                         borderRadius: BorderRadius.circular(16),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             "Top Spending",
                             style: TextStyle(
                               color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.white.withOpacity(0.9),
                               fontSize: 12,
                               fontWeight: FontWeight.w600,
                               letterSpacing: 0.5,
                             ),
                           ),
                           const SizedBox(height: 12),
                           ...topCategories.take(3).map((entry) {
                             final percentage = (_totalCost > 0) ? (entry.value / _totalCost * 100) : 0;
                             return Padding(
                               padding: const EdgeInsets.only(bottom: 8),
                               child: Row(
                                 children: [
                                   Icon(
                                     getModelIcon(entry.key),
                                     size: 16,
                                     color: isDark ? colorScheme.primary : Colors.white.withOpacity(0.9),
                                   ),
                                   const SizedBox(width: 8),
                                   Expanded(
                                     child: Text(
                                       entry.key,
                                       style: TextStyle(
                                         color: isDark ? colorScheme.onSurface : Colors.white.withOpacity(0.9),
                                         fontSize: 12,
                                         fontWeight: FontWeight.w500,
                                       ),
                                     ),
                                   ),
                                   Text(
                                     "${percentage.toStringAsFixed(0)}%",
                                     style: TextStyle(
                                       color: isDark ? colorScheme.onSurface.withOpacity(0.6) : Colors.white.withOpacity(0.7),
                                       fontSize: 11,
                                       fontWeight: FontWeight.w600,
                                     ),
                                   ),
                                   const SizedBox(width: 8),
                                   Text(
                                     "₹${entry.value.toStringAsFixed(0)}",
                                     style: TextStyle(
                                       color: isDark ? colorScheme.primary : Colors.white,
                                       fontSize: 13,
                                       fontWeight: FontWeight.bold,
                                     ),
                                   ),
                                 ],
                               ),
                             );
                           }).toList(),
                         ],
                       ),
                     ),
                 ],
               ),
             ),
           ],
         ),
       ),
     ).animate()
       .fadeIn(duration: 500.ms)
       .slideY(begin: -0.1, duration: 500.ms, curve: Curves.easeOut);
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, bool isDark, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isDark ? colorScheme.primary.withOpacity(0.7) : Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? colorScheme.onSurface.withOpacity(0.6) : Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: isDark ? colorScheme.primary : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalancesList() {
    final sortedBalances = _balances.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final myBalance = _balances['You'] ?? 0.0;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (sortedBalances.where((e) => e.value.abs() >= 0.01).isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Decorative confetti-like circles
              Positioned(
                right: -10,
                top: -10,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.tertiary.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                right: 30,
                bottom: 10,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.secondary.withOpacity(0.05),
                  ),
                ),
              ),
              // Currency watermark
              Positioned(
                left: -15,
                top: -15,
                child: Opacity(
                  opacity: 0.03,
                  child: Icon(
                    Icons.currency_rupee_rounded,
                    size: 100,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              // Content
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "All Settled Up!",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Everyone is square",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.9, 0.9), duration: 400.ms, curve: Curves.easeOut);
    }

    return Column(
      children: sortedBalances.asMap().entries.map((entry) {
          final index = entry.key;
          final e = entry.value;
          final member = e.key;
          final bal = e.value;
          final isMe = member == 'You';
          if (bal.abs() < 0.01) return const SizedBox.shrink();
          
          final isOwed = bal > 0;
          final primaryColor = isOwed 
              ? const Color(0xFF10B981) 
              : const Color(0xFFEF4444);
          final secondaryColor = isOwed 
              ? const Color(0xFF34D399) 
              : const Color(0xFFF87171);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1E1E1E),
                        const Color(0xFF252525),
                      ]
                    : [
                        Colors.white,
                        colorScheme.surfaceContainer.withOpacity(0.3),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Decorative background watermark - Currency Symbol
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Opacity(
                      opacity: 0.03,
                      child: Icon(
                        Icons.currency_rupee_rounded,
                        size: 120,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    right: 40,
                    bottom: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.03),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: 10,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: secondaryColor.withOpacity(0.04),
                      ),
                    ),
                  ),
                  // Status icon watermark
                  Positioned(
                    right: 20,
                    top: 20,
                    child: Opacity(
                      opacity: 0.05,
                      child: Icon(
                        isOwed ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        size: 80,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  // Animated background gradient indicator
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [primaryColor, secondaryColor],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Enhanced Avatar
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [primaryColor, secondaryColor],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  member[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              if (isMe)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: 12,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Member Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      isMe ? "You" : member,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          primaryColor.withOpacity(0.15),
                                          secondaryColor.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isOwed ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                                          size: 14,
                                          color: primaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isOwed ? "Gets back" : "Owes",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "₹${bal.abs().toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: primaryColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  if (isMe && bal < 0)
                                    FilledButton.icon(
                                      onPressed: () {
                                        // Settle logic
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(Icons.check_circle_outline, size: 18),
                                      label: const Text(
                                        "Settle",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
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
                ],
              ),
            ),
          )
          .animate(delay: (100 * index).ms)
          .fadeIn(duration: 500.ms, curve: Curves.easeOut)
          .slideX(begin: -0.1, duration: 500.ms, curve: Curves.easeOutCubic)
          .scale(begin: const Offset(0.95, 0.95), duration: 500.ms, curve: Curves.easeOut);
      }).toList(),
    );
  }

  Widget _buildExpensesTab() {
     if (_groupTransactions.isEmpty) {
         return _buildEmptyState();
     }
     
     final sorted = List<Transaction>.from(_groupTransactions)..sort((a, b) => b.date.compareTo(a.date));
     
     return ListView.separated(
       padding: const EdgeInsets.all(16),
       itemCount: sorted.length,
       separatorBuilder: (_, __) => const SizedBox(height: 12),
       itemBuilder: (context, index) {
         final t = sorted[index];
         return Dismissible(
             key: Key(t.id.toString()),
             background: Container(color: Colors.red, child: Icon(Icons.delete, color: Colors.white)),
             onDismissed: (_) => _deleteTransaction(t),
             child: InkWell(
                 onTap: () => _navigateToAddGroupTransaction(transactionToEdit: t),
                 child: _buildTransactionTile(t)
             )
         );
       },
     );
  }
  
  Widget _buildTransactionTile(Transaction t) {
      if (t.isSettlement) {
          final receiver = (t.split != null && t.split!.isNotEmpty) ? t.split!.keys.first : 'Someone';
          return Center(
              child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                      "${t.paidBy} settled ₹${t.amount.toStringAsFixed(0)} with $receiver",
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
              ),
          );
      }
      
      final isMe = t.paidBy == 'You';
      return Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
         ),
         child: Row(
             children: [
                 Container(
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(
                         color: isMe ? Theme.of(context).colorScheme.primaryContainer : Colors.white,
                         shape: BoxShape.circle,
                     ),
                     child: Icon(
                         getModelIcon(t.category), 
                         size: 20, 
                         color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey
                     ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                     child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                             Text(t.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                             Text(
                                 "${t.paidBy} paid", 
                                 style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)
                             ),
                         ],
                     ),
                 ),
                 Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                         Text("₹${t.amount.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                         Text(DateFormat('MMM d').format(t.date), style: TextStyle(fontSize: 10, color: Colors.grey)),
                     ],
                 )
             ],
         ),
      );
  }
  
  IconData getModelIcon(String category) {
      if (category == 'Food') return Icons.restaurant;
      if (category == 'Travel') return Icons.flight;
      if (category == 'Hotel') return Icons.hotel;
      if (category == 'Shopping') return Icons.shopping_bag;
      if (category == 'Rent') return Icons.home;
      if (category == 'Utilities') return Icons.lightbulb;
      return Icons.receipt;
  }

  Widget _buildInfoTab() {
      final colorScheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Group Members",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1E1E1E),
                          const Color(0xFF252525),
                        ]
                      : [
                          Colors.white,
                          colorScheme.surfaceContainer.withOpacity(0.3),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Decorative background
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withOpacity(0.03),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.secondary.withOpacity(0.03),
                        ),
                      ),
                    ),
                    // Members list
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.primary.withOpacity(0.8),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.people_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${widget.group.members.length} Members",
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Sharing expenses together",
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ...widget.group.members.asMap().entries.map((entry) {
                            final index = entry.key;
                            final member = entry.value;
                            final isYou = member == 'You';
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isYou 
                                    ? colorScheme.primaryContainer.withOpacity(0.3)
                                    : colorScheme.surfaceContainer.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isYou
                                      ? colorScheme.primary.withOpacity(0.3)
                                      : colorScheme.outlineVariant.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isYou
                                            ? [colorScheme.primary, colorScheme.primary.withOpacity(0.8)]
                                            : [colorScheme.tertiary, colorScheme.tertiary.withOpacity(0.8)],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        member[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (isYou)
                                          Text(
                                            "That's you!",
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isYou)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "YOU",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ).animate(delay: (100 * index).ms)
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.1, duration: 400.ms, curve: Curves.easeOut);
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }


  Widget _buildEmptyState() {
     return Center(child: Text("No expenses yet"));
  }
}