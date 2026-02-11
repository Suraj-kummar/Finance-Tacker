import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:project_track_your_finance/modules/statement_import/db/statement_db_helper.dart';
import 'package:project_track_your_finance/modules/statement_import/models/imported_transaction.dart';
import 'package:project_track_your_finance/modules/statement_import/services/file_parser_factory.dart';
import 'package:project_track_your_finance/modules/statement_import/services/normalization_service.dart';

class StatementProvider with ChangeNotifier {
  List<ImportedTransaction> _transactions = [];
  bool _isLoading = false;
  
  List<ImportedTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  final StatementDBHelper _dbHelper = StatementDBHelper.instance;
  final NormalizationService _normalizationService = NormalizationService();

  StatementProvider() {
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _transactions = await _dbHelper.readAllTransactions();
    } catch (e) {
      print("Error fetching statements: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<int> importFile() async {
    int count = 0;
    try {
      // Build Permission Request Logic
       if (Platform.isAndroid) {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          // Only request storage permission on Android 12 (SDK 32) and below
          if (androidInfo.version.sdkInt <= 32) {
             final status = await Permission.storage.request();
             if (status.isDenied) {
                throw Exception("Storage permission denied. Please enable it in Settings.");
             }
             if (status.isPermanentlyDenied) {
                openAppSettings();
                throw Exception("Storage permission permanently denied. Opening settings...");
             }
          }
       }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv', 'xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        _isLoading = true;
        notifyListeners();

        final file = File(result.files.single.path!);
        final parser = FileParserFactory.getParser(result.files.single.path!);
        final parsedTransactions = await parser.parse(file);
        
        // Normalize and Save
        for (var t in parsedTransactions) {
             final cleanName = await _normalizationService.normalizePersonName(t.personName);
             final newT = ImportedTransaction(
                 date: t.date,
                 personName: cleanName,
                 upiId: t.upiId,
                 amount: t.amount,
                 type: t.type,
                 category: t.category,
                 sourceBank: t.sourceBank,
                 note: t.note,
             );
             await _dbHelper.createTransaction(newT);
        }
        
        await fetchTransactions(); // Refresh list
        count = parsedTransactions.length;
      }
      return count;
    } catch (e) {
      print("Error importing file: $e");
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> updateTransaction(ImportedTransaction t, {
      String? personName,
      double? amount,
      String? category,
  }) async {
      final newT = ImportedTransaction(
          id: t.id, // Keep ID
          date: t.date,
          personName: personName ?? t.personName,
          upiId: t.upiId,
          amount: amount ?? t.amount,
          type: t.type,
          category: category ?? t.category,
          sourceBank: t.sourceBank,
          note: t.note,
      );
      
      await _dbHelper.updateTransaction(newT);
      
      // Update local list
      final index = _transactions.indexWhere((tx) => tx.id == t.id);
      if (index != -1) {
          _transactions[index] = newT;
          notifyListeners();
      } else {
        await fetchTransactions();
      }
  }

  Future<void> deleteTransaction(int id) async {
      await _dbHelper.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
  }

  Future<void> applyFilters({
      DateTime? startDate,
      DateTime? endDate,
      double? minAmount,
      double? maxAmount,
      String? personName,
      String? category,
      String? type,
  }) async {
      _isLoading = true;
      notifyListeners();
      try {
          _transactions = await _dbHelper.filterTransactions(
              startDate: startDate,
              endDate: endDate,
              minAmount: minAmount,
              maxAmount: maxAmount,
              personName: personName,
              category: category,
              type: type,
          );
      } catch (e) {
          print(e);
      }
      _isLoading = false;
      notifyListeners();
  }

  Future<void> clearAll() async {
      await _dbHelper.clearAll();
      await fetchTransactions();
  }
}
