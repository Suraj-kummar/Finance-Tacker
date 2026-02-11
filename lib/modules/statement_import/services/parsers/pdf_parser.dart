import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../models/imported_transaction.dart';
import '../file_parser_factory.dart';

class PdfParser implements FileParser {
  @override
  Future<List<ImportedTransaction>> parse(File file) async {
    // Run parsing logic directly on main thread (Reverted optimization)
    return await parsePdfWorker(file.path);
  }
}

/// Top-level function that runs in the isolate
Future<List<ImportedTransaction>> parsePdfWorker(String filePath) async {
  print("DEBUG: Starting Isolate Parse for $filePath");
  try {
    final file = File(filePath);
    if (!file.existsSync()) {
      print("CRITICAL: File not found in isolate: $filePath");
      return [];
    }

    final List<int> bytes = file.readAsBytesSync();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    String text = PdfTextExtractor(document).extractText();
    document.dispose();

    List<ImportedTransaction> transactions = [];
    String lowerText = text.toLowerCase();
    String lowerPath = filePath.toLowerCase();

    // 1. Detect MobiKwik
    bool isMobikwik = lowerText.contains("mobikwik") || 
                      lowerPath.contains("mobikwik") || 
                      (lowerText.contains("wallet balance") && lowerText.contains("supercash"));

    print("DEBUG: isMobikwik=$isMobikwik");

    if (isMobikwik) {
       transactions = parseMobikwik(text);
    }
    
    // 2. Try PhonePe Specific Parser if not found yet
    if (transactions.isEmpty) {
       transactions = parsePhonePe(text);
       print("DEBUG: PhonePe parser found ${transactions.length}");
    }

    // 3. If no transactions found, try Generic Parser
    if (transactions.isEmpty) {
      transactions = parseGeneric(text);
      print("DEBUG: Generic parser found ${transactions.length}");
    }

    return transactions;

  } catch (e) {
    print("CRITICAL: Error in parsePdfWorker: $e");
    return [];
  }
}

/// Helper Parse Functions (Top-level or Static for Isolate access)

List<ImportedTransaction> parseMobikwik(String text) {
  List<ImportedTransaction> transactions = [];
  final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  
  final dateRegex = RegExp(r'^(\d{2}-\d{2}-\d{4})'); 
  final amountRegex = RegExp(r'([\+\-])?\s*(?:Rs\.|₹)\s*([\d,]+(\.\d{2})?)');

  for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (dateRegex.hasMatch(line)) {
          try {
             final dateMatch = dateRegex.firstMatch(line)!;
             DateTime? date = parseDateSafe(dateMatch.group(1)!);
             if (date == null) continue;

             String description = "MobiKwik Transaction";
             double amount = 0;
             String type = "DEBIT";
             bool foundAmount = false;

             for (int k = 1; k <= 3 && (i + k) < lines.length; k++) {
                 String nextLine = lines[i + k];
                 if (amountRegex.hasMatch(nextLine)) {
                     final amountMatch = amountRegex.firstMatch(nextLine)!;
                     String rawAmount = amountMatch.group(2)!.replaceAll(',', '');
                     amount = double.parse(rawAmount);
                     
                     bool isCredit = false;
                     if (amountMatch.group(1) == '+') isCredit = true;
                     
                     if (k > 1) {
                         description = lines[i + 1]; 
                     }
                     
                     if (description.toLowerCase().contains("received from") || 
                         description.toLowerCase().contains("cashback received") ||
                         description.toLowerCase().contains("money added")) {
                         isCredit = true;
                     }

                     type = isCredit ? 'CREDIT' : 'DEBIT';
                     foundAmount = true;
                     break; 
                 }
             }
             
             if (!foundAmount) {
                  String remaining = line.substring(dateMatch.end).trim();
                  if (remaining.isNotEmpty) {
                      final amtMatch = amountRegex.firstMatch(remaining);
                      if (amtMatch != null) {
                           String rawAmount = amtMatch.group(2)!.replaceAll(',', '');
                           amount = double.parse(rawAmount);
                           if (amtMatch.group(1) == '+') type = 'CREDIT';
                           description = remaining.substring(0, amtMatch.start).trim();
                           foundAmount = true;
                      }
                  }
             }

             if (foundAmount) {
                  transactions.add(ImportedTransaction(
                     date: date,
                     personName: description,
                     upiId: "",
                     amount: amount,
                     type: type,
                     sourceBank: "MobiKwik", 
                     category: "Uncategorized",
                 ));
             } 
          } catch (e) {
             // ignore
          }
      }
  }
  return transactions;
}

List<ImportedTransaction> parsePhonePe(String text) {
  List<ImportedTransaction> transactions = [];
  final lines = text.split('\n');
  
  // Revised PhonePe Regex: explicitly look for "Date" header context if possible, 
  // but usually PhonePe PDF is complex.
  // Using the previous regex which worked for some.
  final dateRegex = RegExp(r'(\d{1,2}|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s\d{1,2},?\s\d{4}', caseSensitive: false);
  final amountRegex = RegExp(r'^[₹Rs\.]{1,3}\s?([\d,]+(\.\d{2})?)');
  final paidToRegex = RegExp(r'(Paid to|Transfer to)\s+(.+)', caseSensitive: false);
  final receivedFromRegex = RegExp(r'(Received from|Transfer from)\s+(.+)', caseSensitive: false);

  for (int i = 0; i < lines.length; i++) {
     String line = lines[i].trim();
     if (line.isEmpty) continue;
     
     if (dateRegex.hasMatch(line)) {
        try {
           final dateMatch = dateRegex.firstMatch(line)!;
           String dateStr = dateMatch.group(0)!;
           DateTime? date = parseDateSafe(dateStr);

           if (date == null) continue;
           
           String personName = "Unknown";
           String type = "DEBIT";
           double amount = 0.0;
           bool foundDetails = false;

           // Look ahead context
           for (int j = 0; j <= 5 && (i + j) < lines.length; j++) {
              String seekLine = lines[i+j].trim();
              
              if (paidToRegex.hasMatch(seekLine)) {
                 personName = paidToRegex.firstMatch(seekLine)!.group(2)!.trim();
                 type = 'DEBIT';
              } else if (receivedFromRegex.hasMatch(seekLine)) {
                 personName = receivedFromRegex.firstMatch(seekLine)!.group(2)!.trim();
                 type = 'CREDIT';
              }
              
              if (amountRegex.hasMatch(seekLine) && !seekLine.contains("Transaction ID")) {
                  final match = amountRegex.firstMatch(seekLine)!;
                  String rawAmount = match.group(1)!.replaceAll(',', '');
                   try {
                      double parsed = double.parse(rawAmount);
                      if (parsed > 0 && amount == 0.0) {
                         amount = parsed;
                         foundDetails = true;
                      }
                   } catch (_) {}
              }
           }

           if (foundDetails && amount > 0) {
               transactions.add(ImportedTransaction(
                   date: date,
                   personName: personName,
                   upiId: "",
                   amount: amount,
                   type: type,
                   sourceBank: "PhonePe",
                   category: "Uncategorized",
               ));
           }
        } catch (e) {
           // ignore
        }
     }
  }
  return transactions;
}

List<ImportedTransaction> parseGeneric(String text) {
   List<ImportedTransaction> transactions = [];
   final lines = text.split('\n');

   final dateStartRegex = RegExp(r'^(\d{1,2}[-\./]\d{1,2}[-\./]\d{2,4}|\d{1,2}\s+[a-zA-Z]{3}\s+\d{2,4})');
   final strictAmountRegex = RegExp(r'(?:[₹Rs\.]{1,3}\s*)?([\d,]+\.\d{2}|[\d,]{2,})'); 

   for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (dateStartRegex.hasMatch(line)) {
          try {
             final dateMatch = dateStartRegex.firstMatch(line)!;
             DateTime? date = parseDateSafe(dateMatch.group(0)!);
             if (date == null) continue;

             String remainingText = line.substring(dateMatch.end).trim();
             double amount = 0.0;
             String type = "DEBIT"; 
             
             bool isCredit = line.toLowerCase().contains(" cr ") || line.toLowerCase().contains(" credit ") || line.toLowerCase().contains(" deposit ");
             bool isDebit = line.toLowerCase().contains(" dr ") || line.toLowerCase().contains(" debit ") || line.toLowerCase().contains(" withdrawal ");
             
             if (isCredit) type = "CREDIT";
             if (isDebit) type = "DEBIT";

             final matches = strictAmountRegex.allMatches(remainingText);
             List<double> candidates = [];
             
             for (final m in matches) {
                 String raw = m.group(1)!.replaceAll(',', '');
                 if (!raw.contains('.')) {
                     if (raw.length == 4 && (raw.startsWith("20") || raw.startsWith("19"))) continue; 
                 }
                 double? val = double.tryParse(raw);
                 if (val != null && val > 0) candidates.add(val);
             }

             if (candidates.isNotEmpty) {
                amount = candidates.first; 
             }

             String personName = remainingText;
             for (final m in matches) {
                 personName = personName.replaceAll(m.group(0)!, '');
             }
             
             personName = personName.replaceAll(RegExp(r'\s+'), ' ').trim();
             personName = personName.replaceAll(RegExp(r'(CR|DR|Cr|Dr|Credit|Debit|Transfer|UPI|REF|IMPS|NEFT)'), '').trim();
             personName = personName.replaceAll(RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$'), '');

             if (personName.isEmpty) personName = "Transaction";

             if (amount > 0) {
                 transactions.add(ImportedTransaction(
                     date: date,
                     personName: personName,
                     upiId: "",
                     amount: amount,
                     type: type,
                     sourceBank: "Generic",
                     category: "Uncategorized",
                 ));
             }
          } catch (e) {
             // ignore
          }
      }
   }
   return transactions;
}

DateTime? parseDateSafe(String dateStr) {
  List<String> formats = [
    'dd/MM/yyyy', 'dd-MM-yyyy', 'yyyy-MM-dd', 
    'dd MMM, yyyy', 'MMM dd, yyyy', 
    'dd MMM yyyy', 'dd.MM.yyyy', 'dd/MM/yy'
  ];
  
  for (String fmt in formats) {
     try {
        return DateFormat(fmt).parse(dateStr.replaceAll(RegExp(r'(\d)(st|nd|rd|th)'), r'$1'));
     } catch (_) {}
  }
  return null;
}
