import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class PdfExport {
  static Future<void> exportTransactionsToPdf(
      List<Transaction> transactions) async {
    final pdf = pw.Document();

    // Calculate totals
    final totalIncome = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpenses;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header with watermark
            pw.Stack(
              children: [
                // Watermark
                pw.Positioned(
                  top: 0,
                  right: 0,
                  child: pw.Opacity(
                    opacity: 0.1,
                    child: pw.Transform.rotate(
                      angle: -0.3,
                      child: pw.Text(
                        'Finance Tracker Pro',
                        style: pw.TextStyle(
                          fontSize: 60,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                // Main Header
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
                              'Finance Tracker Pro',
                              style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#10B981'),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Transaction Report',
                              style: const pw.TextStyle(
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
                              'Generated on',
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey600,
                              ),
                            ),
                            pw.Text(
                              DateFormat('MMM dd, yyyy').format(DateTime.now()),
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    pw.Divider(color: PdfColors.grey300),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Summary Cards
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard('Total Income',
                    'Rs. ${totalIncome.toStringAsFixed(2)}', PdfColors.green),
                _buildSummaryCard('Total Expenses',
                    'Rs. ${totalExpenses.toStringAsFixed(2)}', PdfColors.red),
                _buildSummaryCard(
                    'Balance',
                    'Rs. ${balance.toStringAsFixed(2)}',
                    PdfColor.fromHex('#10B981')),
              ],
            ),

            pw.SizedBox(height: 30),

            // Transactions Table
            pw.Text(
              'Transaction Details',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                // Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F3F4F6'),
                  ),
                  children: [
                    _buildTableCell('Date', isHeader: true),
                    _buildTableCell('Description', isHeader: true),
                    _buildTableCell('Category', isHeader: true),
                    _buildTableCell('Type', isHeader: true),
                    _buildTableCell('Amount', isHeader: true),
                  ],
                ),
                // Data Rows
                ...transactions.map((transaction) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(
                          DateFormat('MMM dd').format(transaction.date)),
                      _buildTableCell(transaction.name),
                      _buildTableCell(transaction.category),
                      _buildTableCell(
                        transaction.isIncome ? 'Income' : 'Expense',
                        color: transaction.isIncome
                            ? PdfColors.green
                            : PdfColors.red,
                      ),
                      _buildTableCell(
                        'Rs. ${transaction.amount.toStringAsFixed(2)}',
                        color: transaction.isIncome
                            ? PdfColors.green
                            : PdfColors.red,
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),

            pw.SizedBox(height: 30),

            // Footer watermark
            pw.Center(
              child: pw.Opacity(
                opacity: 0.3,
                child: pw.Text(
                  'Finance Tracker Pro - Your Personal Finance Manager',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
              ),
            ),
          ];
        },
      ),
    );

    // Show print dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildSummaryCard(
      String title, String value, PdfColor color) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(
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
      ),
    );
  }

  static pw.Widget _buildTableCell(String text,
      {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.black : PdfColors.grey800),
        ),
      ),
    );
  }
}
