
import '../database/db_helper.dart';
import '../models/group.dart';
import '../models/transaction.dart';

class GroupRepository {
  /// Fetch all groups from the database
  Future<List<Group>> getGroups() async {
    return await DBHelper.getGroups();
  }

  /// Add a new group
  Future<int> addGroup(Group group) async {
    return await DBHelper.insertGroup(group);
  }

  /// Update an existing group
  Future<int> updateGroup(Group group) async {
    return await DBHelper.updateGroup(group);
  }

  /// Delete a group by ID
  Future<void> deleteGroup(int id) async {
    return await DBHelper.deleteGroup(id);
  }

  /// Get transactions specific to a group
  Future<List<Transaction>> getGroupTransactions(int groupId) async {
    return await DBHelper.getGroupTransactions(groupId);
  }
}
