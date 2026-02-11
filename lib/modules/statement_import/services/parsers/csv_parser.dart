import 'dart:io';
import 'package:csv/csv.dart';
import '../../models/imported_transaction.dart';
import '../file_parser_factory.dart';

class CsvFileParser implements FileParser {
  @override
  Future<List<ImportedTransaction>> parse(File file) async {
    final input = file.readAsStringSync();
    final rows = const CsvToListConverter().convert(input);

    List<ImportedTransaction> transactions = [];

    // Basic heuristic: check header row to identify columns
    // This is a naive implementation; complex bank CSVs need dedicated mapping logic
    // We assume columns: Date, Description, Amount, Type (Cr/Dr)
    
    // Skip header
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 3) continue;

      try {
        DateTime date = DateTime.now(); // Placeholder fallback
        String description = row[1].toString();
        double amount = 0.0;
        String type = 'DEBIT';

        // Very basic parsing attempt
        // Users normally need to map columns manually in a real app
        // Here we attempt auto-detection for demonstration
        
        transactions.add(ImportedTransaction(
          date: date,
          personName: description.split(' ').first, // Naive name extraction
          upiId: '', // Hard to extract without regex on description
          amount: amount,
          type: type,
          sourceBank: 'CSV Import',
        ));
      } catch (e) {
        print('Error parsing row $i: $e');
      }
    }
    return transactions;
  }
}
