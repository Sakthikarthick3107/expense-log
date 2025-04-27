import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../models/expense2.dart';
import 'package:expense_log/services/notification_service.dart';

class ReportService {
  const ReportService();

  Future<void> prepareDailyExpenseReport(List<Expense2> expenses) async {
    final logoBytes = await rootBundle
        .load('assets/icons/terminal.png')
        .then((value) => value.buffer.asUint8List());
    final poppinsFont =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-Regular.ttf'));
    final pdf = pw.Document();
    final groupedExpenses = <String, List<Expense2>>{};
    for (var expense in expenses) {
      if (!groupedExpenses.containsKey(expense.expenseType.name)) {
        groupedExpenses[expense.expenseType.name] = [];
      }
      groupedExpenses[expense.expenseType.name]?.add(expense);
    }

    String expenseDate =
        '${expenses[0].date.day}-${expenses[0].date.month}-${expenses[0].date.year}';

    pdf.addPage(
      pw.MultiPage(
          pageTheme: pw.PageTheme(
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Opacity(
                opacity: 0.1,
                child: pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(logoBytes),
                    width: 300,
                    height: 300,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          footer: (context) {
            return pw.Container(
                alignment: pw.Alignment.center,
                margin: const pw.EdgeInsets.only(top: 5),
                child: pw.Column(children: [
                  pw.Text(
                    'Expense Log -  Daily Expense Report ${expenseDate}',
                    style: pw.TextStyle(
                      font: poppinsFont,
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Generated at - ${DateTime.now().toString()}',
                    style: pw.TextStyle(
                      font: poppinsFont,
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ]));
          },
          build: (context) => [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Centered heading
                    pw.Center(
                      child: pw.Text(
                        'Daily Expense Report',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          font: poppinsFont,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Center(
                      child: pw.Text(
                        expenseDate,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          font: poppinsFont,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    ...groupedExpenses.entries.map((entry) {
                      final expenseType = entry.key;
                      final expenseList = entry.value;
                      final totalExpense = expenseList.fold(
                          0.0, (sum, item) => sum + item.price);

                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Table(border: pw.TableBorder.all(), columnWidths: {
                            0: pw.FlexColumnWidth(2),
                            1: pw.FlexColumnWidth(1)
                          }, children: [
                            pw.TableRow(
                                decoration:
                                    pw.BoxDecoration(color: PdfColors.grey300),
                                children: [
                                  pw.Padding(
                                      padding: const pw.EdgeInsets.all(8),
                                      child: pw.Column(
                                          crossAxisAlignment:
                                              pw.CrossAxisAlignment.start,
                                          children: [
                                            pw.Text('${expenseType}',
                                                style: pw.TextStyle(
                                                    font: poppinsFont,
                                                    fontSize: 18,
                                                    fontWeight:
                                                        pw.FontWeight.bold)),
                                            pw.Text(
                                                '${expenseList[0].expenseType.description}',
                                                style: pw.TextStyle(
                                                    font: poppinsFont))
                                          ])),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8),
                                    child: pw.Text('₹${totalExpense}',
                                        style: pw.TextStyle(font: poppinsFont)),
                                  )
                                ])
                          ]),
                          pw.Table(
                            border: pw.TableBorder.all(),
                            columnWidths: {
                              0: pw.FlexColumnWidth(2),
                              1: pw.FlexColumnWidth(1),
                            },
                            children: [
                              ...expenseList.map((expense) => pw.TableRow(
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(8),
                                        child: pw.Text(expense.name,
                                            style: pw.TextStyle(
                                                font: poppinsFont)),
                                      ),
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(8),
                                        child: pw.Text('₹${expense.price}',
                                            style: pw.TextStyle(
                                                font: poppinsFont)),
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                        ],
                      );
                    }),

                    pw.SizedBox(height: 20),
                    pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Total : ₹${expenses.fold(0.0, (sum, item) => sum + item.price)}',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              font: poppinsFont,
                            ),
                          ),
                        ]),
                  ],
                ),
              ]),
    );
    final output = await getExternalStorageDirectory();
    final filePath = '${output!.path}/daily_expense_report_${expenseDate}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    await NotificationService.showDownloadCompletedNotification(file);
    // await OpenFile.open(filePath);
    // await downloadPdf(file);
  }

  // Future<void> downloadPdf(File file) async {
  //   await FlutterDownloader.enqueue(
  //     url: Uri.file(file.path).toString(), // works for uri files
  //     savedDir: file.parent.path,
  //     fileName: file.uri.pathSegments.last,
  //     showNotification: true,
  //     openFileFromNotification: true,
  //   );
  // }

// Future<void> downloadPdfInLayout(pw.Document pdf) async {
//   await Printing.layoutPdf(
//     onLayout: (PdfPageFormat format) async => pdf.save(),
//   );
// }
}
