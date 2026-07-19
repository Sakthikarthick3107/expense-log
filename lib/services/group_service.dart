import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/services/audit_log_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/group.dart';

class GroupService extends ChangeNotifier {
  final _groupBox = Hive.box<Group>('groupsBox');

  List<Group> getGroups() => _groupBox.values.toList();

  Group? getById(int id) {
    try {
      return _groupBox.values.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  bool isGroupExist(Group group) {
    return _groupBox.values
        .any((g) => g.name.toLowerCase() == group.name.toLowerCase());
  }

  Future<int> createGroup(Group group) async {
    final checkIfExist = _groupBox.get(group.id);
    if (checkIfExist == null) {
      if (isGroupExist(group)) {
        return 0;
      }
      _groupBox.put(group.id, group);
      AuditLogService.writeLog('Created group - ${group.name}');
      notifyListeners();
      return 1;
    } else {
      AuditLogService.writeLog('Updated group - ${group.name}');
      _groupBox.put(group.id, group);
      notifyListeners();
      return 1;
    }
  }

  int deleteGroup(int id) {
    AuditLogService.writeLog('Deleted group - ${getById(id)?.name}');
    _groupBox.delete(id);
    notifyListeners();
    return 1;
  }

  List<Expense2> getGroupExpenses(int groupId) {
    final expenseBox = Hive.box<Expense2>('expense2Box');
    return expenseBox.values
        .where((e) => e.groupId == groupId)
        .toList();
  }

  List<Expense2> getIndividualExpenses() {
    final expenseBox = Hive.box<Expense2>('expense2Box');
    return expenseBox.values
        .where((e) => e.groupId == null || e.mappedUserName == 'Me')
        .toList();
  }
}
