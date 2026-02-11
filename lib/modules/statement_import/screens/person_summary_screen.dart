import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../providers/statement_provider.dart';

class PersonSummaryScreen extends StatelessWidget {
  const PersonSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Person Analysis", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: Consumer<StatementProvider>(
        builder: (context, provider, _) {
          // Group by Person with detailed stats
          Map<String, _PersonStats> stats = {};
          
          for (var t in provider.transactions) {
            final person = t.personName;
            if (!stats.containsKey(person)) {
              stats[person] = _PersonStats();
            }
            
            if (t.type == 'CREDIT') {
              stats[person]!.income += t.amount;
              stats[person]!.transactionCount++;
            } else {
              stats[person]!.expense += t.amount;
              stats[person]!.transactionCount++;
            }
          }
          
          // Convert to list and sort by highest activity (total volume)
          final sortedPeople = stats.entries.toList()
             ..sort((a,b) => (b.value.income + b.value.expense).compareTo(a.value.income + a.value.expense));

          if (sortedPeople.isEmpty) {
             return Center(
               child: Text("No transaction data available", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
             );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            physics: const BouncingScrollPhysics(),
            itemCount: sortedPeople.length,
            itemBuilder: (context, index) {
               final entry = sortedPeople[index];
               final person = entry.key;
               final stat = entry.value;
               final net = stat.income - stat.expense;
               
               return Container(
                 margin: const EdgeInsets.only(bottom: 16),
                 decoration: BoxDecoration(
                   color: colorScheme.surface,
                   borderRadius: BorderRadius.circular(24),
                   border: Border.all(color: colorScheme.outline.withOpacity(0.05)),
                   boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                   ],
                 ),
                 child: Theme(
                   data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                   child: ExpansionTile(
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                     tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                     leading: CircleAvatar(
                       radius: 24,
                       backgroundColor: colorScheme.primary.withOpacity(0.1),
                       child: Text(
                         person.isNotEmpty ? person[0].toUpperCase() : '?',
                         style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 18),
                       ),
                     ),
                     title: Text(
                       person, 
                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                       maxLines: 1, overflow: TextOverflow.ellipsis
                     ),
                     subtitle: Padding(
                       padding: const EdgeInsets.only(top: 4),
                       child: Text(
                         "${stat.transactionCount} transactions",
                         style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                       ),
                     ),
                     trailing: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       crossAxisAlignment: CrossAxisAlignment.end,
                       children: [
                         Text(
                           "₹${NumberFormat.compact().format(net.abs())}",
                           style: TextStyle(
                             fontWeight: FontWeight.bold,
                             fontSize: 16,
                             color: net >= 0 ? Colors.green : Colors.red,
                           ),
                         ),
                         Text(
                           net >= 0 ? "You received" : "You paid",
                           style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withOpacity(0.5)),
                         ),
                       ],
                     ),
                     children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                               color: colorScheme.surfaceVariant.withOpacity(0.3),
                               borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                               mainAxisAlignment: MainAxisAlignment.spaceAround,
                               children: [
                                  _buildDetailCol("Total Paid", stat.expense, Colors.redAccent),
                                  Container(width: 1, height: 40, color: colorScheme.outline.withOpacity(0.2)),
                                  _buildDetailCol("Total Received", stat.income, Colors.green),
                               ],
                            ),
                          ),
                        )
                     ],
                   ),
                 ),
               );
            },
          );
        }
      ),
    );
  }

  Widget _buildDetailCol(String label, double amount, Color color) {
     return Column(
       children: [
         Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
         const SizedBox(height: 4),
         Text(
           "₹${NumberFormat('#,##0').format(amount)}",
           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
         ),
       ],
     );
  }
}

class _PersonStats {
  double income = 0;
  double expense = 0;
  int transactionCount = 0;
}
