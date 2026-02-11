import 'dart:io';
import 'package:excel/excel.dart';
import '../../models/imported_transaction.dart';
import '../file_parser_factory.dart';

class ExcelFileParser implements FileParser {
  @override
  Future<List<ImportedTransaction>> parse(File file) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    
    List<ImportedTransaction> transactions = [];

    for (var table in excel.tables.keys) {
      if (excel.tables[table] == null) continue;
      
      for (var row in excel.tables[table]!.rows) {
        // Skip header - heuristic
        if (row.isEmpty) continue;
        
        // Try to identify columns by type
        // Date col, String col, Num col
        // ...
      }
    }
    
    return transactions;
  }
}
