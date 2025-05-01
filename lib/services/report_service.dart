import 'dart:io';
import 'package:expense_log/models/date_range.dart';
import 'package:expense_log/utility/pdf_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../models/expense2.dart';
import 'package:expense_log/services/notification_service.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';

class ReportService {
  const ReportService();

  Future<void> prepareDailyExpenseReport(List<Expense2> expenses) async {
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
          pageTheme: PdfHelper.pageBackground(),
          footer: (context) {
            return PdfHelper.footer(
                footerTitle:
                    'Expense Log -  Daily Expense Report $expenseDate');
          },
          build: (context) => [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    ...PdfHelper.header(
                        reportTitle: 'Daily Expense Report',
                        subtitle: expenseDate),
                    ...PdfHelper.generateExpenseTableGrpByDay(expenses),
                    pw.SizedBox(height: 20),
                    pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          PdfHelper.text(
                            'Total : ₹${expenses.fold(0.0, (sum, item) => sum + item.price)}',
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ]),
                  ],
                ),
              ]),
    );
    final pdfBytes = await pdf.save();
    await savePdfAndShowNotification(
        pdfBytes, 'daily_expense_report', expenseDate);
  }

  Future<void> prepareMetricsReport(
      List<Expense2> expenses,
      List<String> selectedTypes,
      String viewBy,
      DateRange selectedRange) async {
    final pdf = pw.Document();
    final filteredExpenses = expenses
        .where((expense) => selectedTypes.contains(expense.expenseType.name))
        .toList();

    final Map<String, double> typeTotals = {};
    final Map<DateTime, double> dayTotals = {};

    for (var expense in filteredExpenses) {
      typeTotals.update(
        expense.expenseType.name,
        (existing) => existing + expense.price,
        ifAbsent: () => expense.price,
      );

      DateTime dateKey =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      dayTotals.update(
        dateKey,
        (existing) => existing + expense.price,
        ifAbsent: () => expense.price,
      );
    }

    final sortedDayEntries = dayTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final summaryTotals = viewBy == 'By type'
        ? typeTotals
        : Map.fromEntries(
            sortedDayEntries.map(
              (entry) => MapEntry(
                DateFormat("d MMM yy").format(entry.key),
                entry.value,
              ),
            ),
          );

    String startDate =
        '${selectedRange.start.day}-${selectedRange.start.month}-${selectedRange.start.year}';
    String endDate =
        '${selectedRange.end.day}-${selectedRange.end.month}-${selectedRange.end.year}';

    filteredExpenses.sort((a, b) => a.date.compareTo(b.date));

    final groupedByDate = <String, List<Expense2>>{};
    for (var expense in filteredExpenses) {
      String expenseDate =
          '${expense.date.day}-${expense.date.month}-${expense.date.year}';
      if (!groupedByDate.containsKey(expenseDate)) {
        groupedByDate[expenseDate] = [];
      }
      groupedByDate[expenseDate]?.add(expense);
    }

    final groupedByType = <String, List<Expense2>>{};
    for (var expense in filteredExpenses) {
      String typeName = expense.expenseType.name;
      if (!groupedByType.containsKey(typeName)) {
        groupedByType[typeName] = [];
      }
      groupedByType[typeName]?.add(expense);
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: PdfHelper.pageBackground(),
        footer: (context) {
          return PdfHelper.footer(
            footerTitle: 'Expense Log - Metrics Report',
          );
        },
        build: (context) {
          List<pw.Widget> widgets = [];

          widgets.addAll(PdfHelper.header(
            reportTitle: 'Metrics Report',
            subtitle: '${startDate} to ${endDate}',
          ));

          widgets.add(
            pw.Text(
              'Expense ${viewBy} - Summary',
              style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
            ),
          );

          widgets.add(pw.SizedBox(height: 5));

          widgets.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: summaryTotals.entries.map((entry) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: PdfHelper.text(
                          entry.key,
                          fontSize: 15,
                        ),
                      ),
                      PdfHelper.text(
                        '₹${entry.value.toStringAsFixed(2)}',
                        fontSize: 15,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );

          widgets.add(pw.SizedBox(height: 5));
          widgets.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                PdfHelper.text(
                  'Total: ₹${filteredExpenses.fold(0.0, (sum, item) => sum + item.price)}',
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 20));

          if (viewBy == 'By day') {
            for (var entry in groupedByDate.entries) {
              final dateExpenses = entry.value;
              String dateTitle = entry.key;

              widgets.add(
                pw.Text(
                  '$dateTitle',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              );

              widgets
                  .addAll(PdfHelper.generateExpenseTableGrpByDay(dateExpenses));
              widgets.add(pw.SizedBox(height: 20));
            }
          } else if (viewBy == 'By type') {
            for (var entry in groupedByType.entries) {
              final typeKey = entry.key;
              final typeValue = entry.value;
              widgets.add(
                pw.Text(
                  '$typeKey',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              );

              widgets
                  .addAll(PdfHelper.generateExpenseTableGrpByType(typeValue));
              widgets.add(pw.SizedBox(height: 20));
            }
          }

          return widgets;
        },
      ),
    );

    final pdfBytes = await pdf.save();
    await savePdfAndShowNotification(
        pdfBytes, 'metrics_report', '${startDate}_to_${endDate}');
  }

  Future<void> savePdfAndShowNotification(
      Uint8List pdfBytes, String reportName, String expenseDate) async {
    final output = await getDownloadsDirectory();
    if (output == null) return;
    final String folderName = 'ExpenseLog_Reports';

    final Directory folder = Directory('${output!.path}/$folderName');

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final filePath = '${folder.path}/${reportName}_$expenseDate.pdf';
    final file = File(filePath);
    print('File saved at: $filePath');
    await file.writeAsBytes(pdfBytes);
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
