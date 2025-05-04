import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class AuditLogService {
  static const _folderName = 'logs';
  static const _fileName = 'audit_log.txt';

  static Future<void> writeLog(String message) async {
    final file = await _getLogFile();
    final timestamp =
        DateFormat('yyyy-MM-dd hh:mm:ss a').format(DateTime.now());
    await file.writeAsString('$timestamp - $message\n', mode: FileMode.append);
  }

  static Future<List<String>> readLogs() async {
    final file = await _getLogFile();
    if (!await file.exists()) return [];
    final lines = await file.readAsLines();
    return lines.reversed.toList();
  }

  static Future<void> clearLogs() async {
    final file = await _getLogFile();
    if (await file.exists()) {
      await file.writeAsString('');
    }
  }

  static Future<File> _getLogFile() async {
    final baseDir = await getExternalStorageDirectory();
    final logsDir = Directory('${baseDir!.path}/$_folderName');

    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }

    return File('${logsDir.path}/$_fileName');
  }
}
