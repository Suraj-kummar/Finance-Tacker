import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:project_track_your_finance/modules/statement_import/providers/statement_provider.dart';
import 'package:project_track_your_finance/modules/statement_import/models/imported_transaction.dart';
import 'package:project_track_your_finance/modules/statement_import/utils/statement_pdf_export.dart';
import 'person_summary_screen.dart';

class ImportDashboardScreen extends StatefulWidget {
  const ImportDashboardScreen({super.key});

  @override
  State<ImportDashboardScreen> createState() => _ImportDashboardScreenState();
}

class _ImportDashboardScreenState extends State<ImportDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<StatementProvider>(context, listen: false).applyFilters(
        personName: query.isEmpty ? null : query,
      );
    });
  }

  // ... (build method remains same)

  Future<void> _exportToPDF(BuildContext context) async {
    try {
      final provider = Provider.of<StatementProvider>(context, listen: false);
      final transactions = provider.transactions;
      
      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No data to export!")));
        return;
      }

      final totalIncome = transactions.where((t) => t.type == 'CREDIT').fold(0.0, (sum, t) => sum + t.amount);
      final totalExpense = transactions.where((t) => t.type == 'DEBIT').fold(0.0, (sum, t) => sum + t.amount);
      final balance = totalIncome - totalExpense;

      await StatementPdfExporter.exportTransactions(
        transactions: transactions,
        totalIncome: totalIncome,
        totalExpenses: totalExpense,
        balance: balance,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
    }
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Clear All Data?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          "This will permanently delete multiple imported statement transactions. This action cannot be undone.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<StatementProvider>(context, listen: false).clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All data cleared successfully"), backgroundColor: Colors.red),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Clear All", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ... (rest of the code)



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Financial Insights", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context),
          ),
          IconButton(
             icon: const Icon(Icons.more_vert_rounded),
             onPressed: () => _showMoreMenu(context),
          )
        ],
      ),
      body: Consumer<StatementProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }

          // if (provider.transactions.isEmpty) {
          //    return _buildEmptyState(context, colorScheme);
          // }

          // Calculate Summaries
          final totalIncome = provider.transactions.where((t) => t.type == 'CREDIT').fold(0.0, (sum, t) => sum + t.amount);
          final totalExpense = provider.transactions.where((t) => t.type == 'DEBIT').fold(0.0, (sum, t) => sum + t.amount);
          final balance = totalIncome - totalExpense;

          // Calculate Summaries ensure no zero division issues if needed (though 0/0 is handled in UI usually by staying 0)
          
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                       // 1. Balance Card (Hero Style)
                       Container(
                         width: double.infinity,
                         padding: const EdgeInsets.all(24),
                         decoration: BoxDecoration(
                           gradient: LinearGradient(
                             colors: [colorScheme.primary, colorScheme.secondary],
                             begin: Alignment.topLeft,
                             end: Alignment.bottomRight,
                           ),
                           borderRadius: BorderRadius.circular(24),
                           boxShadow: [
                             BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                           ],
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text("Total Balance", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                             const SizedBox(height: 8),
                             Text("₹${NumberFormat('#,##0.00').format(balance)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                             const SizedBox(height: 24),
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 _buildMiniStat("Income", totalIncome, Icons.arrow_downward, Colors.greenAccent.shade100),
                                 _buildMiniStat("Expense", totalExpense, Icons.arrow_upward, Colors.redAccent.shade100),
                               ],
                             )
                           ],
                         ),
                       ),
                       const SizedBox(height: 24),

                       // Quick Actions Row
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceAround,
                         children: [
                            GestureDetector(
                              onTap: () => _showImportOptions(context),
                              child: _buildQuickAction(
                                context, 
                                Icons.file_upload_outlined, 
                                "Import",
                                [const Color(0xFF34C759), const Color(0xFFb0e4b9)], // Green
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PersonSummaryScreen())),
                              child: _buildQuickAction(
                                context, 
                                Icons.pie_chart_outline_rounded, 
                                "Analysis",
                                [const Color(0xFF007AFF), const Color(0xFF3395FF)], // Blue
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _exportToPDF(context),
                              child: _buildQuickAction(
                                context, 
                                Icons.picture_as_pdf_rounded, 
                                "PDF",
                                [const Color(0xFFFF9500), const Color(0xFFFFCC00)], // Orange
                              ),
                            ),
                             GestureDetector(
                              onTap: () => _confirmClearAll(context),
                              child: _buildQuickAction(
                                context, 
                                Icons.delete_outline_rounded, 
                                "Clear All",
                                [const Color(0xFFFF3B30), const Color(0xFFFF6961)], // Red
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showFilterSheet(context),
                              child: _buildQuickAction(
                                context, 
                                Icons.filter_list_rounded, 
                                "Filter",
                                [const Color(0xFF9C27B0), const Color(0xFFBA68C8)], // Purple
                              ),
                            ),
                         ],
                       ),

                       const SizedBox(height: 24),
                       
                       // 2. Chart Section
                       if (totalExpense > 0 || totalIncome > 0)
                          Container(
                            height: 180,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: PieChart(
                                    PieChartData(
                                      sections: [
                                        PieChartSectionData(
                                          color: colorScheme.primary,
                                          value: totalIncome,
                                          title: '',
                                          radius: 25,
                                        ),
                                        PieChartSectionData(
                                          color: Colors.redAccent,
                                          value: totalExpense,
                                          title: '',
                                          radius: 25,
                                        ),
                                      ],
                                      centerSpaceRadius: 40,
                                      sectionsSpace: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLegendItem("Income", colorScheme.primary, "${((totalIncome / (totalIncome + totalExpense)) * 100).toStringAsFixed(0)}%"),
                                    const SizedBox(height: 12),
                                    _buildLegendItem("Expense", Colors.redAccent, "${((totalExpense / (totalIncome + totalExpense)) * 100).toStringAsFixed(0)}%"),
                                  ],
                                )
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        
                     ],
                   ),
                 ),
               ),




              // Search Bar Pinned
              SliverAppBar(
                backgroundColor: theme.scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                pinned: true,
                automaticallyImplyLeading: false,
                toolbarHeight: 80,
                flexibleSpace: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                        hintText: "Search transactions...",
                        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.1))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefixIcon: Icon(Icons.search_rounded, size: 22, color: colorScheme.onSurface.withOpacity(0.4)),
                        suffixIcon: _searchController.text.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                                setState(() {});
                              },
                            ) 
                          : null,
                    ),
                  ),
                ),
              ),
              
              // 3. Transactions List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final t = provider.transactions[index];
                      return _buildTransactionTile(t, context, colorScheme);
                    },
                    childCount: provider.transactions.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<StatementProvider>(
          builder: (context, provider, _) => FloatingActionButton.extended(
            onPressed: () => provider.importFile(),
            icon: const Icon(Icons.add_rounded),
            label: const Text("Import"),
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
          )
      ),
    );
  }



  Widget _buildLegendItem(String label, Color color, String value) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }

  Widget _buildTransactionTile(ImportedTransaction t, BuildContext context, ColorScheme colorScheme) {
    final isCredit = t.type.toUpperCase() == 'CREDIT';
    final isPhonePe = t.sourceBank == 'PhonePe';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: isCredit ? Colors.green : Colors.red,
            size: 22,
          ),
        ),
        title: Text(
          isPhonePe ? (isCredit ? "Received from ${t.personName}" : "Paid to ${t.personName}") : t.personName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(DateFormat('MMM dd').format(t.date), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              if (t.category != "Uncategorized") ...[
                 const SizedBox(width: 12),
                 Icon(Icons.label_outline_rounded, size: 12, color: Colors.grey.shade500),
                 const SizedBox(width: 4),
                 Text(t.category, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ]
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${isCredit ? '+' : '-'} ₹${t.amount.toStringAsFixed(0)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCredit ? Colors.green : colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
          ],
        ),
        onTap: () => _showEditTransactionSheet(context, t),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
      return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.analytics_outlined, size: 60, color: colorScheme.primary),
              ),
              const SizedBox(height: 24),
              Text("No Data Yet", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text("Import a statement to get insights", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () async {
                    try {
                       final count = await Provider.of<StatementProvider>(context, listen: false).importFile();
                       if (context.mounted && count > 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Import Successful!"), backgroundColor: Colors.green));
                       }
                    } catch (e) {
                       if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red));
                       }
                    }
                },
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text("Import Statement"),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        );
  }

  void _showMoreMenu(BuildContext context) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;

      showModalBottomSheet(
         context: context,
         backgroundColor: Colors.transparent,
         elevation: 0,
         builder: (context) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 // Glassy Container for Actions
                 ClipRRect(
                   borderRadius: BorderRadius.circular(20),
                   child: BackdropFilter(
                     filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                     child: Container(
                       decoration: BoxDecoration(
                         color: (isDark ? Colors.grey.shade900 : Colors.white).withOpacity(0.8),
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(color: Colors.white.withOpacity(0.1)),
                       ),
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                             _buildGlassyMenuItem("Import New Statement", Icons.add_circle_outline_rounded, colorScheme.primary, () {
                                 Navigator.pop(context);
                                 Provider.of<StatementProvider>(context, listen: false).importFile();
                             }),
                             Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
                             _buildGlassyMenuItem("Person-wise Analysis", Icons.pie_chart_outline_rounded, colorScheme.secondary, () {
                                 Navigator.pop(context);
                                 Navigator.push(context, MaterialPageRoute(builder: (context) => PersonSummaryScreen()));
                             }),
                             Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
                             _buildGlassyMenuItem("Export Data", Icons.ios_share_rounded, colorScheme.tertiary, () {
                                 Navigator.pop(context);
                                 _exportToPDF(context);
                             }),
                         ],
                       ),
                     ),
                   ),
                 ),
                 
                 const SizedBox(height: 12),
                 
                 // Cancel / Close Button (iOS Style)
                 GestureDetector(
                   onTap: () => Navigator.pop(context),
                   child: Container(
                     width: double.infinity,
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     decoration: BoxDecoration(
                       color: (isDark ? Colors.grey.shade900 : Colors.white),
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: const Center(
                       child: Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     ),
                   ),
                 ),
                 
                 const SizedBox(height: 8),
                 // Destructive Action Separate
                 GestureDetector(
                   onTap: () {
                       Navigator.pop(context);
                       _confirmClearAll(context);
                   },
                   child: Container(
                     width: double.infinity,
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     decoration: BoxDecoration(
                       color: Colors.red.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(20),
                       border: Border.all(color: Colors.red.withOpacity(0.2)),
                     ),
                     child: const Center(
                       child: Text("Clear All Data", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                     ),
                   ),
                 ),
              ],
            ),
         )
      );
  }

  Widget _buildGlassyMenuItem(String title, IconData icon, Color color, VoidCallback onTap) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 16),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 14),
              ],
            ),
          ),
        ),
      );
  }

  void _showEditTransactionSheet(BuildContext context, ImportedTransaction t) {
      final nameController = TextEditingController(text: t.personName);
      final amountController = TextEditingController(text: t.amount.toString());
      final categoryController = TextEditingController(text: t.category);
      
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      const Text("Edit Transaction", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                              labelText: "Person Name",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                          ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                          children: [
                              Expanded(
                                  child: TextField(
                                      controller: amountController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                          labelText: "Amount",
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                          filled: true,
                                          fillColor: Theme.of(context).colorScheme.surface,
                                      ),
                                  ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: TextField(
                                      controller: categoryController,
                                      decoration: InputDecoration(
                                          labelText: "Category",
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                          filled: true,
                                          fillColor: Theme.of(context).colorScheme.surface,
                                      ),
                                  ),
                              ),
                          ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                              onPressed: () {
                                  Provider.of<StatementProvider>(context, listen: false).updateTransaction(t, 
                                      personName: nameController.text,
                                      amount: double.tryParse(amountController.text),
                                      category: categoryController.text
                                  );
                                  Navigator.pop(ctx);
                              },
                              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              child: const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                          onPressed: () {
                              Navigator.pop(ctx);
                              Provider.of<StatementProvider>(context, listen: false).deleteTransaction(t.id!);
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          label: const Text("Delete Transaction", style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(height: 16),
                  ],
              ),
          )
      );
  }

  void _showFilterSheet(BuildContext context) {
      double minAmt = 0;
      double maxAmt = 100000;
      String type = 'All';
      DateTime? startDate;
      DateTime? endDate;
      final nameController = TextEditingController();
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;

      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          builder: (ctx) => StatefulBuilder(
              builder: (ctx, setState) => Container(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, 
                      left: 16, 
                      right: 16, 
                      top: 48 // Top padding for visual spacing
                  ),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          // 1. Glassy Form Container
                          Flexible(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.grey.shade900 : Colors.white).withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                          Center(
                                            child: Container(
                                              width: 40, height: 4, 
                                              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text("Filter Options", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                                          const SizedBox(height: 24),
                                          
                                          // Type
                                          Text("Transaction Type", style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                                          const SizedBox(height: 12),
                                          Row(
                                              children: [
                                                  _buildFilterChip("All", type == 'All', colorScheme, () => setState(() => type = 'All')),
                                                  const SizedBox(width: 8),
                                                  _buildFilterChip("Income", type == 'CREDIT', colorScheme, () => setState(() => type = 'CREDIT')),
                                                  const SizedBox(width: 8),
                                                  _buildFilterChip("Expense", type == 'DEBIT', colorScheme, () => setState(() => type = 'DEBIT')),
                                              ],
                                          ),
                                          
                                          const SizedBox(height: 24),
                                          
                                          // Date
                                          Text("Date Range", style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                                          const SizedBox(height: 12),
                                          GestureDetector(
                                            onTap: () async {
                                                final picked = await showDateRangePicker(
                                                    context: context,
                                                    firstDate: DateTime(2020),
                                                    lastDate: DateTime.now(),
                                                    initialDateRange: startDate != null && endDate != null ? DateTimeRange(start: startDate!, end: endDate!) : null,
                                                    builder: (context, child) => Theme(
                                                      data: theme.copyWith(colorScheme: colorScheme.copyWith(surface: theme.scaffoldBackgroundColor)),
                                                      child: child!,
                                                    )
                                                );
                                                if (picked != null) setState(() { startDate = picked.start; endDate = picked.end; });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                              decoration: BoxDecoration(
                                                color: colorScheme.surface.withOpacity(0.5),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.calendar_today_rounded, size: 18, color: colorScheme.primary),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    startDate == null ? "Select Date Range" : "${DateFormat('MMM dd').format(startDate!)} - ${DateFormat('MMM dd').format(endDate!)}",
                                                    style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 24),
                                          
                                          // Search
                                          Text("Search Name / ID", style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                                          const SizedBox(height: 12),
                                          TextField(
                                              controller: nameController,
                                              style: TextStyle(color: colorScheme.onSurface),
                                              decoration: InputDecoration(
                                                  hintText: "e.g. Swiggy, Uber...",
                                                  hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
                                                  filled: true,
                                                  fillColor: colorScheme.surface.withOpacity(0.5),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: colorScheme.onSurface.withOpacity(0.4)),
                                              ),
                                          ),
                                          
                                          const SizedBox(height: 24),

                                          // Amount
                                          Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                  Text("Amount Range", style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                                                  Text("₹${minAmt.toInt()} - ₹${maxAmt.toInt()}", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 13)),
                                              ],
                                          ),
                                          SliderTheme(
                                            data: SliderTheme.of(context).copyWith(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8)),
                                            child: RangeSlider(
                                                values: RangeValues(minAmt, maxAmt),
                                                min: 0, max: 100000, divisions: 100,
                                                activeColor: colorScheme.primary,
                                                inactiveColor: colorScheme.primary.withOpacity(0.2),
                                                onChanged: (val) => setState(() { minAmt = val.start; maxAmt = val.end; })
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // 2. Action Buttons (Floating)
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                     // Clear Logic
                                     setState(() {
                                         type = 'All'; minAmt = 0; maxAmt = 100000; startDate = null; endDate = null; nameController.clear();
                                     });
                                     Provider.of<StatementProvider>(context, listen: false).applyFilters(
                                         type: null, minAmount: null, maxAmount: null, startDate: null, endDate: null, personName: null
                                     );
                                     Navigator.pop(ctx);
                                  },
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: (isDark ? Colors.grey.shade800 : Colors.white).withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Center(child: Text("Reset", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onTap: () {
                                      Provider.of<StatementProvider>(context, listen: false).applyFilters(
                                          type: type == 'All' ? null : type,
                                          minAmount: minAmt,
                                          maxAmount: maxAmt,
                                          startDate: startDate,
                                          endDate: endDate,
                                          personName: nameController.text.isNotEmpty ? nameController.text : null,
                                      );
                                      Navigator.pop(ctx);
                                  },
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                                    ),
                                    child: const Center(child: Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16))),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                  ),
              )
          )
      );
  }

  Widget _buildFilterChip(String label, bool isSelected, ColorScheme colorScheme, VoidCallback onTap) {
      return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.transparent : colorScheme.outline.withOpacity(0.1)),
                  boxShadow: isSelected ? [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
              ),
              child: Text(
                  label,
                  style: TextStyle(
                      color: isSelected ? Colors.white : colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                  ),
              ),
          ),
      );
  }

  Widget _buildMiniStat(String label, double amount, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
             Text("₹${NumberFormat.compact().format(amount)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        )
      ],
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
  Future<void> _handleImport(BuildContext context) async {
      // 1. Show Loading Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.blueAccent),
                const SizedBox(width: 20),
                const Text("Processing Statement...\nPlease wait.", style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );

      try {
        // 2. Perform Import
        final count = await Provider.of<StatementProvider>(context, listen: false).importFile();
        
        // 3. Close Loading Dialog
        if (mounted) Navigator.pop(context); 

        // 4. Show Success
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text("Successfully imported $count transactions!"),
               backgroundColor: Colors.green,
               behavior: SnackBarBehavior.floating,
             ),
           );
        }
      } catch (e) {
        // 3. Close Loading Dialog (on Error)
        if (mounted) Navigator.pop(context);

        // 5. Show Error Dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Import Failed"),
              content: Text(e.toString().replaceAll("Exception:", "").trim()),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK", style: TextStyle(color: Colors.redAccent)),
                )
              ],
            ),
          );
        }
      }
  }

  void _showImportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Statement Source",
              style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSourceOption(
                  sheetContext, 
                  "PhonePe", 
                  Icons.account_balance_wallet_rounded, 
                  const Color(0xFF673AB7), // Purple
                  () {
                    Navigator.pop(sheetContext);
                    _handleImport(context); // Use stable outer context
                  }
                ),
                _buildSourceOption(
                  sheetContext, 
                  "MobiKwik", 
                  Icons.flash_on_rounded, 
                  const Color(0xFF0091EA), // Blue
                  () {
                    Navigator.pop(sheetContext);
                    _handleImport(context); // Use stable outer context
                  }
                ),
                _buildSourceOption(
                  sheetContext, 
                  "Other", 
                  Icons.receipt_long_rounded, 
                  const Color(0xFF757575), // Grey
                  () {
                    Navigator.pop(sheetContext);
                    _handleImport(context); // Use stable outer context
                  }
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
