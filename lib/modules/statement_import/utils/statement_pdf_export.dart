import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/imported_transaction.dart';

class StatementPdfExporter {
  static Future<void> exportTransactions({
    required List<ImportedTransaction> transactions,
    required double totalIncome,
    required double totalExpenses,
    required double balance,
  }) async {
    final pdf = pw.Document();
    
    // Separate income and expenses
    final incomeTransactions = transactions.where((t) => t.type == 'CREDIT').toList();
    final expenseTransactions = transactions.where((t) => t.type == 'DEBIT').toList();
    
    // Category breakdown for expenses
    final Map<String, double> categoryTotals = {};
    for (var t in expenseTransactions) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header with PRO watermark
          pw.Stack(
            children: [
              // Large PRO Watermark in background
              pw.Positioned(
                right: -80,
                top: -40,
                child: pw.Opacity(
                  opacity: 0.03,
                  child: pw.Text(
                    'Finance Tracker PRO',
                    style: pw.TextStyle(
                      fontSize: 60,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF10B981), // Green color
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
                          pw.Row(
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.all(8),
                                decoration: pw.BoxDecoration(
                                  color: const PdfColor.fromInt(0xFF10B981),
                                  borderRadius: pw.BorderRadius.circular(8),
                                ),
                                child: pw.Text(
                                  'PRO',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white,
                                  ),
                                ),
                              ),
                              pw.SizedBox(width: 12),
                              pw.Text(
                                'Financial Insights',
                                style: pw.TextStyle(
                                  fontSize: 28,
                                  fontWeight: pw.FontWeight.bold,
                                  color: const PdfColor.fromInt(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Statement Analysis Report',
                            style: pw.TextStyle(
                              fontSize: 14,
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
                  pw.Container(
                    height: 3,
                    decoration: pw.BoxDecoration(
                      gradient: const pw.LinearGradient(
                        colors: [
                          PdfColor.fromInt(0xFF10B981),
                          PdfColor.fromInt(0xFF34D399),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          pw.SizedBox(height: 24),
          
          // Summary Section with green theme
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                colors: [
                  PdfColor.fromInt(0xFF10B981),
                  PdfColor.fromInt(0xFF059669),
                ],
              ),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem('Total Income', 'Rs.${totalIncome.toStringAsFixed(2)}', PdfColors.white),
                    _buildSummaryItem('Total Expenses', 'Rs.${totalExpenses.toStringAsFixed(2)}', PdfColors.white),
                    _buildSummaryItem('Balance', 'Rs.${balance.toStringAsFixed(2)}', PdfColors.white),
                  ],
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 24),
          
          // Transaction Statistics
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF0FDF4),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFF10B981),
                      width: 1,
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        incomeTransactions.length.toString(),
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF10B981),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Income Transactions',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFFEF2F2),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFFEF4444),
                      width: 1,
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        expenseTransactions.length.toString(),
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFFEF4444),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Expense Transactions',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 24),
          
          // Category Breakdown
          if (sortedCategories.isNotEmpty) ...[
            pw.Text(
              'Top Spending Categories',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 12),
            ...sortedCategories.take(5).map((entry) {
              final percentage = (totalExpenses > 0) ? (entry.value / totalExpenses * 100) : 0;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(12),
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
                          'Rs.${entry.value.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            pw.SizedBox(height: 24),
          ],
          
          // Transactions List
          pw.Text(
            'Transaction History',
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
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF10B981),
                ),
                children: [
                  _buildTableHeader('Description', isHeader: true),
                  _buildTableHeader('Category', isHeader: true),
                  _buildTableHeader('Type', isHeader: true),
                  _buildTableHeader('Amount', isHeader: true),
                  _buildTableHeader('Date', isHeader: true),
                ],
              ),
              // Rows
              ...transactions.take(50).map((t) { // Limit to 50 for performance
                return pw.TableRow(
                  children: [
                    _buildTableCell(t.personName), // Use personName as description
                    _buildTableCell(t.category),
                    _buildTableCell(t.type == 'CREDIT' ? 'Credit' : 'Debit'),
                    _buildTableCell('Rs.${t.amount.toStringAsFixed(2)}', bold: true),
                    _buildTableCell(DateFormat('MMM dd').format(t.date)),
                  ],
                );
              }).toList(),
            ],
          ),
          
          // Footer with PRO branding
          pw.SizedBox(height: 40),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                colors: [
                  PdfColor.fromInt(0xFF10B981),
                  PdfColor.fromInt(0xFF059669),
                ],
              ),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Generated by Financial Insights PRO',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
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
      name: 'Financial_Insights_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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
            color: PdfColors.white,
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
  
  static pw.Widget _buildTableHeader(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: isHeader ? PdfColors.white : PdfColors.grey800,
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
