import 'package:flutter/material.dart';
import 'dart:collection';
import '../database/db_helper.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

// Efficient transaction manager using optimized data structures
class TransactionManager {
  // HashMap for O(1) lookups
  final Map<int, Transaction> _transactions = HashMap<int, Transaction>();
  
  // Index for fast category-based filtering - O(1) category filtering
  final Map<String, Set<int>> _categoryIndex = HashMap<String, Set<int>>();
  
  // Index for fast date-based filtering
  final Map<String, Set<int>> _dateIndex = HashMap<String, Set<int>>();
  
  // Sorted lists for efficient range queries
  List<Transaction> _sortedByDate = [];
  List<Transaction> _sortedByAmount = [];
  
  bool _needsResorting = false;

  // Add transaction with indexing
  void addTransaction(Transaction transaction) {
    _transactions[transaction.id!] = transaction;
    _updateIndices(transaction, isAdd: true);
    _needsResorting = true;
  }

  // Update transaction efficiently
  void updateTransaction(Transaction oldTransaction, Transaction newTransaction) {
    if (oldTransaction.id == newTransaction.id) {
      _updateIndices(oldTransaction, isAdd: false);
      _transactions[newTransaction.id!] = newTransaction;
      _updateIndices(newTransaction, isAdd: true);
      _needsResorting = true;
    }
  }

  // Remove transaction with cleanup
  void removeTransaction(Transaction transaction) {
    _transactions.remove(transaction.id);
    _updateIndices(transaction, isAdd: false);
    _needsResorting = true;
  }

  // Update indices for fast filtering
  void _updateIndices(Transaction transaction, {required bool isAdd}) {
    final category = transaction.category;
    final dateKey = _getDateKey(transaction.date);
    final id = transaction.id!;

    if (isAdd) {
      _categoryIndex.putIfAbsent(category, () => <int>{}).add(id);
      _dateIndex.putIfAbsent(dateKey, () => <int>{}).add(id);
    } else {
      _categoryIndex[category]?.remove(id);
      _dateIndex[dateKey]?.remove(id);
      
      // Clean up empty sets
      if (_categoryIndex[category]?.isEmpty ?? false) {
        _categoryIndex.remove(category);
      }
      if (_dateIndex[dateKey]?.isEmpty ?? false) {
        _dateIndex.remove(dateKey);
      }
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get all transactions
  List<Transaction> getAllTransactions() {
    return _transactions.values.toList();
  }

  // Fast category filtering - O(1) category lookup + O(n) where n is transactions in category
  List<Transaction> getTransactionsByCategory(String category) {
    final ids = _categoryIndex[category] ?? <int>{};
    return ids.map((id) => _transactions[id]!).toList();
  }

  // Fast search with multiple criteria
  List<Transaction> searchTransactions({
    String? query,
    String? category,
    bool? isIncome,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) {
    var results = _transactions.values.toList();

    // Apply filters efficiently
    if (category != null && category != 'All') {
      final categoryIds = _categoryIndex[category] ?? <int>{};
      results = results.where((t) => categoryIds.contains(t.id)).toList();
    }

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results.where((t) => 
        t.name.toLowerCase().contains(lowerQuery) ||
        t.category.toLowerCase().contains(lowerQuery)
      ).toList();
    }

    if (isIncome != null) {
      results = results.where((t) => t.isIncome == isIncome).toList();
    }

    if (startDate != null) {
      results = results.where((t) => t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate)).toList();
    }

    if (endDate != null) {
      results = results.where((t) => t.date.isBefore(endDate) || t.date.isAtSameMomentAs(endDate)).toList();
    }

    if (minAmount != null) {
      results = results.where((t) => t.amount >= minAmount).toList();
    }

    if (maxAmount != null) {
      results = results.where((t) => t.amount <= maxAmount).toList();
    }

    return results;
  }

  // Get sorted transactions efficiently
  List<Transaction> getSortedTransactions(SortType sortType) {
    if (_needsResorting) {
      _sortedByDate = _transactions.values.toList()..sort((a, b) => b.date.compareTo(a.date));
      _sortedByAmount = _transactions.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));
      _needsResorting = false;
    }

    switch (sortType) {
      case SortType.dateNewest:
        return List.from(_sortedByDate);
      case SortType.dateOldest:
        return _sortedByDate.reversed.toList();
      case SortType.amountHighest:
        return List.from(_sortedByAmount);
      case SortType.amountLowest:
        return _sortedByAmount.reversed.toList();
      case SortType.nameAZ:
        return _transactions.values.toList()..sort((a, b) => a.name.compareTo(b.name));
      case SortType.nameZA:
        return _transactions.values.toList()..sort((a, b) => b.name.compareTo(a.name));
    }
  }

  // Get categories with transaction counts
  Map<String, int> getCategoryStats() {
    final stats = <String, int>{};
    for (final entry in _categoryIndex.entries) {
      stats[entry.key] = entry.value.length;
    }
    return stats;
  }

  // Clear all data
  void clear() {
    _transactions.clear();
    _categoryIndex.clear();
    _dateIndex.clear();
    _sortedByDate.clear();
    _sortedByAmount.clear();
    _needsResorting = false;
  }
}

enum SortType {
  dateNewest,
  dateOldest,
  amountHighest,
  amountLowest,
  nameAZ,
  nameZA,
}



// ... (TransactionManager remains unchanged)

class TransactionProvider extends ChangeNotifier {
  final TransactionManager _manager = TransactionManager();
  final TransactionRepository _repository = TransactionRepository();
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Transaction> get transactions => _manager.getAllTransactions();

  // Efficient transaction operations
  Future<void> fetchTransactions() async {
    _setLoading(true);
    _clearError();
    
    try {
      final transactions = await _repository.getTransactions();
      
      _manager.clear();
      for (final transaction in transactions) {
        _manager.addTransaction(transaction);
      }
      
    } catch (e) {
      _setError('Failed to load transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      final id = await _repository.addTransaction(transaction);
      final newTransaction = Transaction(
        id: id,
        name: transaction.name,
        amount: transaction.amount,
        isIncome: transaction.isIncome,
        category: transaction.category,
        date: transaction.date,
        groupId: transaction.groupId,
        paidBy: transaction.paidBy,
        split: transaction.split,
      );
      
      _manager.addTransaction(newTransaction);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add transaction: $e');
    }
  }

  Future<void> updateTransaction(Transaction updatedTransaction) async {
    try {
      await _repository.updateTransaction(updatedTransaction);
      
      final oldTransaction = _manager._transactions[updatedTransaction.id];
      if (oldTransaction != null) {
        _manager.updateTransaction(oldTransaction, updatedTransaction);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update transaction: $e');
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _repository.deleteTransaction(id);
      
      final transaction = _manager._transactions[id];
      if (transaction != null) {
        _manager.removeTransaction(transaction);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to delete transaction: $e');
    }
  }

  // Advanced filtering and searching
  List<Transaction> getFilteredTransactions({
    String? query,
    String? category,
    bool? isIncome,
    DateTime? startDate,
    DateTime? endDate,
    SortType sortType = SortType.dateNewest,
  }) {
    var results = _manager.searchTransactions(
      query: query,
      category: category,
      isIncome: isIncome,
      startDate: startDate,
      endDate: endDate,
    );

    // Apply sorting
    switch (sortType) {
      case SortType.dateNewest:
        results.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortType.dateOldest:
        results.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortType.amountHighest:
        results.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortType.amountLowest:
        results.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case SortType.nameAZ:
        results.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortType.nameZA:
        results.sort((a, b) => b.name.compareTo(a.name));
        break;
    }

    return results;
  }

  // Financial calculations
  double getTotalIncome() {
    return _manager.getAllTransactions()
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenses() {
    return _manager.getAllTransactions()
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getBalance() => getTotalIncome() - getTotalExpenses();

  Map<String, double> getCategoryExpenses() {
    final expenses = <String, double>{};
    
    for (final transaction in _manager.getAllTransactions()) {
      if (!transaction.isIncome) {
        expenses[transaction.category] = (expenses[transaction.category] ?? 0) + transaction.amount;
      }
    }
    
    return expenses;
  }

  Map<String, int> getCategoryStats() => _manager.getCategoryStats();

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}