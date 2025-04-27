import 'package:expense_log/services/settings_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

import 'package:provider/provider.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<FileSystemEntity> pdfFiles = [];

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    final Directory reportsDir = Directory(
      '/storage/emulated/0/Android/data/com.expenseapp.expense_log/files/downloads/ExpenseLog_Reports',
    );

    if (await reportsDir.exists()) {
      final files = reportsDir.listSync();
      files.sort((a, b) {
        final aTime = a.statSync().modified;
        final bTime = b.statSync().modified;
        return bTime.compareTo(aTime); // latest first
      });

      setState(() {
        pdfFiles = files.where((file) => file.path.endsWith('.pdf')).toList();
      });
    }
  }

  Future<void> deleteReport(FileSystemEntity file) async {
    try {
      await file.delete();
      fetchReports();
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  void openReport(FileSystemEntity file) {
    OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
        builder: (context, settingsService, child) {
      return Scaffold(
        body: pdfFiles.isEmpty
            ? const Center(child: Text('No downloads found.'))
            : ListView.builder(
                itemCount: pdfFiles.length,
                itemBuilder: (context, index) {
                  final file = pdfFiles[index];
                  final filename = file.path.split('/').last;
                  return Container(
                    margin: EdgeInsets.only(bottom: 4),
                    child: Material(
                        elevation: settingsService.getElevation() ? 4 : 0,
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).cardColor,
                        child: ListTile(
                          leading: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                            size: 18,
                          ),
                          title: Text(
                            filename,
                            style: TextStyle(fontSize: 12),
                          ),
                          subtitle: Text(
                            file.statSync().modified.toString(),
                            style: const TextStyle(
                                fontSize: 8, color: Colors.grey),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.grey,
                              size: 18,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Report?'),
                                  content: Text(
                                      'Are you sure you want to delete "$filename"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        deleteReport(file);
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          onTap: () => openReport(file),
                        )),
                  );
                },
              ),
      );
    });
  }
}
