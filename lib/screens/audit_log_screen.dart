import 'package:expense_log/widgets/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:expense_log/services/audit_log_service.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<String> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await AuditLogService.readLogs();
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  Future<void> _clearLogs() async {
    await AuditLogService.clearLogs();
    setState(() {
      _logs = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text("No logs available."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final regex = RegExp(
                      r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?: [AP]M)?) - (.*)$',
                    );

                    final match = regex.firstMatch(log);

                    String timestamp = 'Unknown Time';
                    String message = log;

                    if (match != null && match.groupCount == 2) {
                      timestamp = match.group(1)!;
                      message = match.group(2)!;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 8),
                      // decoration: BoxDecoration(
                      //   border: Border(
                      //       bottom: BorderSide(color: Colors.grey.shade300)),
                      // ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              timestamp,
                              style: const TextStyle(fontSize: 8),
                            ),
                          ),
                          const SizedBox(width: 1),
                          Expanded(
                            child: Text(
                              message,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          WarningDialog.showWarning(
              context: context,
              title: 'Clear logs',
              message:
                  'Are you sure to clear all logs. Deleted logs cannot be reverted',
              onConfirmed: _clearLogs);
        },
        child: Icon(Icons.cleaning_services),
      ),
    );
  }
}
