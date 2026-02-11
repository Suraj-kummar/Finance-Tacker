import '../database/db_helper.dart';
import '../models/transaction.dart';

class TransactionRepository {
  /// Fetch all transactions from the database
  Future<List<Transaction>> getTransactions() async {
    return await DBHelper.getTransactions();
  }

  /// Add a new transaction
  Future<int> addTransaction(Transaction transaction) async {
    return await DBHelper.insertTransaction(transaction);
  }

  /// Update an existing transaction
  Future<int> updateTransaction(Transaction transaction) async {
    return await DBHelper.updateTransaction(transaction);
  }

  /// Delete a transaction by ID
  Future<void> deleteTransaction(int id) async {
    return await DBHelper.deleteTransaction(id);
  }
}
