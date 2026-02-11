import 'dart:io';
import 'package:project_track_your_finance/modules/statement_import/services/parsers/csv_parser.dart';
import 'package:project_track_your_finance/modules/statement_import/services/parsers/excel_parser.dart';
import 'package:project_track_your_finance/modules/statement_import/services/parsers/pdf_parser.dart';
import '../models/imported_transaction.dart';

abstract class FileParser {
  Future<List<ImportedTransaction>> parse(File file);
}

class FileParserFactory {
  static FileParser getParser(String path) {
    print("Parsing file at path: $path");
    if (path.toLowerCase().endsWith('.pdf')) {
      return PdfParser();
    } else if (path.toLowerCase().endsWith('.csv')) {
      return CsvFileParser();
    } else if (path.toLowerCase().endsWith('.xlsx') || path.toLowerCase().endsWith('.xls')) {
      return ExcelFileParser();
    }
    throw Exception('Unsupported file format');
  }
}
