


import 'package:expense_log/models/upi.dart';
import 'package:hive/hive.dart';

class UpiService{
  final _upiBox = Hive.box<UpiLog>('upiLogBox');

  Future<void> createLog(String message) async {
    final newLog = UpiLog(
      message: message,
      timestamp: DateTime.now(),
    );

    await _upiBox.add(newLog);
  }

  Future<List<UpiLog>> getAllLogs() async {
    final allLogs = List<UpiLog>.from(_upiBox.values);

    allLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return allLogs;
  }
}