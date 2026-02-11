import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/group.dart';
import '../models/transaction.dart';

class GroupPdfExporter {
  static Future<void> exportGroupTransactions({
    required Group group,
    required List<Transaction> transactions,
    required double totalCost,
    required double myShare,
    required double myContribution,
    required Map<String, double> balances,
  }) async {
    final pdf = pw.Document();
    
    // Calculate stats
    final nonSettlementTransactions = transactions.where((t) => !t.isSettlement).toList();
    final categoryTotals = <String, double>{};
    for (var t in nonSettlementTransactions) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header with watermark
          pw.Stack(
            children: [
              // Watermark
              pw.Positioned(
                right: -30,
                top: -30,
                child: pw.Opacity(
                  opacity: 0.05,
                  child: pw.Text(
                    'Rs.',
                    style: pw.TextStyle(
                      fontSize: 180,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Header content
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Finance Tracker',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            group.name,
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '${group.type.toUpperCase()} • ${group.members.length} Members',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Generated',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.Text(
                            DateFormat('MMM dd, yyyy').format(DateTime.now()),
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            DateFormat('hh:mm a').format(DateTime.now()),
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(color: PdfColors.grey300, thickness: 2),
                ],
              ),
            ],
          ),
          
          pw.SizedBox(height: 20),
          
          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColors.blue200, width: 1),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem('Total Expenses', 'Rs.${totalCost.toStringAsFixed(2)}', PdfColors.blue800),
                    _buildSummaryItem('Your Share', 'Rs.${myShare.toStringAsFixed(2)}', PdfColors.orange800),
                    _buildSummaryItem('You Paid', 'Rs.${myContribution.toStringAsFixed(2)}', PdfColors.green800),
                  ],
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 24),
          
          // Members Section
          pw.Text(
            'Members',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.members.map((member) {
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: member == 'You' ? PdfColors.blue100 : PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(16),
                  border: pw.Border.all(
                    color: member == 'You' ? PdfColors.blue300 : PdfColors.grey400,
                  ),
                ),
                child: pw.Text(
                  member,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: member == 'You' ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: member == 'You' ? PdfColors.blue800 : PdfColors.grey800,
                  ),
                ),
              );
            }).toList(),
          ),
          
          pw.SizedBox(height: 24),
          
          // Balances Section
          pw.Text(
            'Balances',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),
          ...balances.entries.where((e) => e.value.abs() >= 0.01).map((entry) {
            final isOwed = entry.value > 0;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: isOwed ? PdfColors.green50 : PdfColors.red50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(
                  color: isOwed ? PdfColors.green200 : PdfColors.red200,
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    entry.key,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    isOwed 
                        ? 'Gets back Rs.${entry.value.abs().toStringAsFixed(2)}'
                        : 'Owes Rs.${entry.value.abs().toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: isOwed ? PdfColors.green800 : PdfColors.red800,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          pw.SizedBox(height: 24),
          
          // Transactions Section
          pw.Text(
            'Transactions (${nonSettlementTransactions.length})',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),
          
          // Transactions Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableHeader('Description'),
                  _buildTableHeader('Category'),
                  _buildTableHeader('Paid By'),
                  _buildTableHeader('Amount'),
                  _buildTableHeader('Date'),
                ],
              ),
              // Rows
              ...nonSettlementTransactions.map((t) {
                return pw.TableRow(
                  children: [
                    _buildTableCell(t.name),
                    _buildTableCell(t.category),
                    _buildTableCell(t.paidBy ?? 'Unknown'),
                    _buildTableCell('Rs.${t.amount.toStringAsFixed(2)}', bold: true),
                    _buildTableCell(DateFormat('MMM dd').format(t.date)),
                  ],
                );
              }).toList(),
            ],
          ),
          
          pw.SizedBox(height: 24),
          
          // Category Breakdown
          if (categoryTotals.isNotEmpty) ...[
            pw.Text(
              'Category Breakdown',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 12),
            ...categoryTotals.entries.map((entry) {
              final percentage = (totalCost > 0) ? (entry.value / totalCost * 100) : 0;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      entry.key,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Row(
                      children: [
                        pw.Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Text(
                          'Rs.${entry.value.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
          
          // Footer with watermark
          pw.SizedBox(height: 40),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Generated by Finance Tracker App',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    
    // Show print/save dialog
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${group.name}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }
  
  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
      ),
    );
  }
  
  static pw.Widget _buildTableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey800,
        ),
      ),
    );
  }
}
