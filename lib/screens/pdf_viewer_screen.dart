import 'dart:io';

import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class PdfViewerScreen extends StatelessWidget {
  final File file;

  const PdfViewerScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(
          file.path.split('/').last,
          style: TextStyle(fontSize: 12),
        )),
        body: PDFView(
          filePath: file.path,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          onError: (error) {
            MessageWidget.showToast(
                context: context, message: "PDFView error: $error", status: 0);
          },
          onPageError: (page, error) {
            MessageWidget.showToast(
                context: context,
                message: 'Error on page $page: $error',
                status: 0);
          },
        ),
        floatingActionButton: Container(
          margin: EdgeInsets.only(right: 10, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                onPressed: () async {
                  await Share.shareXFiles([XFile(file.path)],
                      text: 'Share this expense report');
                },
                child: const Icon(Icons.share_rounded),
                tooltip: 'Share Report',
              ),
              SizedBox(
                width: 5,
              ),
              FloatingActionButton(
                onPressed: () {
                  OpenFile.open(file.path);
                },
                child: const Icon(Icons.open_in_new),
                tooltip: 'Open externally',
              ),
            ],
          ),
        ));
  }
}
