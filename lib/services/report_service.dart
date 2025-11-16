import 'dart:io';
import 'package:expense_log/models/account.dart';
import 'package:expense_log/models/date_range.dart';
import 'package:expense_log/services/audit_log_service.dart';
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

    AuditLogService.writeLog(
        'Downloaded Daily expense report for $expenseDate');
  }

  Future<void> prepareTypeReport(List<Expense2> expenses,
      List<String> selectedTypes, DateRange selectedRange) async {
    final pdf = pw.Document();
    final filteredExpenses = expenses
        .where((expense) => selectedTypes.contains(expense.expenseType.name))
        .toList();

    final Map<String, double> typeTotals = {};

    for (var expense in filteredExpenses) {
      typeTotals.update(
        expense.expenseType.name,
        (existing) => existing + expense.price,
        ifAbsent: () => expense.price,
      );
    }

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
            footerTitle:
                'Expense Log - Type ${expenses.first.expenseType.name} Report',
          );
        },
        build: (context) {
          List<pw.Widget> widgets = [];

          widgets.addAll(PdfHelper.header(
            reportTitle: 'Type Report',
            subtitle: '${startDate} to ${endDate}',
          ));

          widgets.add(
            pw.Text(
              'Expense Type - ${expenses.first.expenseType.name}',
              style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
            ),
          );

          widgets.add(pw.SizedBox(height: 5));

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

          for (var entry in groupedByType.entries) {
            final typeKey = entry.key;
            final typeValue = entry.value;
            widgets.add(
              pw.Text(
                '$typeKey',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            );

            widgets.addAll(PdfHelper.generateExpenseTableGrpByType(typeValue));
            widgets.add(pw.SizedBox(height: 20));
          }

          return widgets;
        },
      ),
    );

    final pdfBytes = await pdf.save();
    await savePdfAndShowNotification(
        pdfBytes,
        'type_${expenses.first.expenseType.name}_report',
        '${startDate}_to_${endDate}');

    AuditLogService.writeLog(
        'Downloaded Expense typee report for ${expenses.first.expenseType.name} - duration ${startDate}_to_${endDate}');
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

    AuditLogService.writeLog(
        'Downloaded Metrics report with ${viewBy} for duration ${startDate}_to_${endDate}');
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

  Future<void> prepareAccountExpenseReport(
    Account account, List<Expense2> expenses,DateTime? fromDate, DateTime? toDate) async {
  final pdf = pw.Document();

  final totalSpent =
      expenses.fold<double>(0.0, (sum, e) => sum + e.price);

  // Group by date (yyyy-MM-dd)
  final Map<String, List<Expense2>> grouped = {};
  for (final e in expenses) {
    final key = DateFormat("yyyy-MM-dd").format(e.date);
    grouped.putIfAbsent(key, () => []).add(e);
  }

  // Sort by date desc
  final sortedDates = grouped.keys.toList()
    ..sort((a, b) => b.compareTo(a));

  pdf.addPage(
    pw.MultiPage(
      pageTheme: PdfHelper.pageBackground(),
      footer: (_) =>
          PdfHelper.footer(footerTitle: "Account Expense Report"),
      build: (context) => [
        ...PdfHelper.header(
          reportTitle: "Account Report",
          subtitle: "${account.name} (${account.code})",
        ),
        if(fromDate != null && toDate != null)
          pw.Center(
            child : PdfHelper.text(
            "${DateFormat("d MMM yyyy").format(fromDate)} to ${DateFormat("d MMM yyyy").format(toDate)}",
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            align: pw.TextAlign.center
          )
          )
          ,
        if (account.description != null &&
            account.description!.isNotEmpty)
        PdfHelper.text(
          "${account.description}",
          fontSize: 14,
          fontWeight: pw.FontWeight.bold
        ),
        pw.SizedBox(height: 8),
        // Summary Box
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              PdfHelper.text(
                "Total Transactions: ${expenses.length}",
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
              PdfHelper.text(
                "Total Spent: ₹${totalSpent.toStringAsFixed(2)}",
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 12),

        // FULL 4 COLUMN TABLE
        ...sortedDates.map((date) {
          final list = grouped[date]!;
          final dayTotal =
              list.fold<double>(0.0, (s, e) => s + e.price);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Date header row
              pw.Table(
                columnWidths: {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: PdfHelper.text(
                          DateFormat("d MMM yyyy")
                              .format(DateTime.parse(date)),
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: PdfHelper.text(
                          "₹ ${dayTotal.toStringAsFixed(2)}",
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Column Headings
              pw.Table(
                columnWidths: {
                  0: pw.FlexColumnWidth(1.2), // Time
                  1: pw.FlexColumnWidth(2.7), // Name
                  2: pw.FlexColumnWidth(2.2), // Type
                  3: pw.FlexColumnWidth(1.2), // Amount
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: PdfHelper.text("Time",
                            fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: PdfHelper.text("Name",
                            fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: PdfHelper.text("Type",
                            fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: PdfHelper.text("Amount",
                            fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),

              // Transaction Rows
              pw.Table(
                columnWidths: {
                  0: pw.FlexColumnWidth(1.2),
                  1: pw.FlexColumnWidth(2.7),
                  2: pw.FlexColumnWidth(2.2),
                  3: pw.FlexColumnWidth(1.2),
                },
                children: list.map((e) {
                  final time =
                      DateFormat("hh:mm a").format(e.date.toLocal());
                  final type = e.expenseType.name;

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: PdfHelper.text(time, fontSize: 9),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: PdfHelper.text(e.name, fontSize: 9),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: PdfHelper.text(type, fontSize: 9),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: PdfHelper.text(
                            "₹${e.price.toStringAsFixed(2)}",
                            fontSize: 9),
                      ),
                    ],
                  );
                }).toList(),
              ),

              pw.SizedBox(height: 12),
            ],
          );
        }).toList(),
      ],
    ),
  );

  final pdfBytes = await pdf.save();
  final  dateDuration = (fromDate != null && toDate != null)
      ? '${fromDate.day}-${fromDate.month}-${fromDate.year}_to_${toDate.day}-${toDate.month}-${toDate.year}'
      : DateFormat("dd-MM-yyyy").format(DateTime.now());
  await savePdfAndShowNotification(
        pdfBytes, 'accounts_report_${account.name}', '${dateDuration}');

    AuditLogService.writeLog(
        'Downloaded Accounts Report for ${account.name} ${dateDuration}');
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
