import 'dart:io';

import 'package:expense_log/models/upi.dart';
import 'package:expense_log/services/upi_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class UpiLogs extends StatefulWidget {
  const UpiLogs({super.key});

  @override
  State<UpiLogs> createState() => _UpiLogsState();
}

class _UpiLogsState extends State<UpiLogs> {
  late UpiService _upiService;
  String smsLog = '';

  @override
  void initState() {
    super.initState();
    loadSmsLog();
    _upiService = Provider.of<UpiService>(context, listen: false);
  }

  Future<void> loadSmsLog() async {
    final status = await Permission.storage.request();
    // final dir = await getApplicationDocumentsDirectory();
    // final file = File('${dir.path}/upi_logs.txt');
    final dir = await getExternalStorageDirectory(); // External app-specific
    final file = File('${dir!.path}/upi_logs.txt');
    // final file = File('/storage/emulated/0/Download/upi_logs.txt');

    if (await file.exists()) {
      final content = await file.readAsString();

      setState(() {
        smsLog = content.length < 10 ? 'Empty file' : content;
      });
    } else {
      setState(() {
        smsLog = 'No log file found.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Text(smsLog),
      ),
    );
    // }
    // @override
    // Widget build(BuildContext context) {
    //   return Scaffold(
    //     body: FutureBuilder<List<UpiLog>>(
    //       future: _upiService.getAllLogs(),
    //       builder: (context, snapshot) {
    //         if (snapshot.connectionState == ConnectionState.waiting) {
    //           return const Center(child: CircularProgressIndicator());
    //         } else if (snapshot.hasError) {
    //           return Center(child: Text('Error: ${snapshot.error}'));
    //         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
    //           return const Center(child: Text('No UPI logs available.'));
    //         } else {

    //           final logs = snapshot.data!;
    //           return ListView.builder(
    //             itemCount: logs.length,
    //             itemBuilder: (context, index) {
    //               final log = logs[index];
    //               return ListTile(
    //                 title: Text(log.message),
    //                 subtitle: Text(log.timestamp.toString()),
    //               );
    //             },
    //           );
    //         }
    //       },
    //     ),
    //   );
  }
}
