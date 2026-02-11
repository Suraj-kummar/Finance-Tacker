
import 'package:flutter/foundation.dart';
import '../repositories/group_repository.dart';
import '../models/group.dart';
import '../models/transaction.dart';

class GroupProvider with ChangeNotifier {
  final GroupRepository _repository = GroupRepository();
  List<Group> _groups = [];
  bool _isLoading = false;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;

  Future<void> loadGroups() async {
    _isLoading = true;
    notifyListeners();
    try {
      _groups = await _repository.getGroups();
    } catch (e) {
      debugPrint('Error loading groups: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGroup(Group group) async {
    try {
      await _repository.addGroup(group);
      await loadGroups();
    } catch (e) {
      debugPrint('Error adding group: $e');
      rethrow;
    }
  }

  Future<void> updateGroup(Group group) async {
    try {
      await _repository.updateGroup(group);
      await loadGroups();
    } catch (e) {
      debugPrint('Error updating group: $e');
      rethrow;
    }
  }

  Future<void> deleteGroup(int id) async {
    try {
      await _repository.deleteGroup(id);
      await loadGroups();
    } catch (e) {
      debugPrint('Error deleting group: $e');
      rethrow;
    }
  }

  Future<List<Transaction>> getGroupTransactions(int groupId) async {
    try {
      return await _repository.getGroupTransactions(groupId);
    } catch (e) {
      debugPrint('Error loading group transactions: $e');
      return [];
    }
  }
}
