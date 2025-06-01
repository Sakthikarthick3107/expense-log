import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:expense_log/models/expense2.dart';

class PdfHelper {
  static late pw.Font poppinsFont;
  static late Uint8List logoBytes;

  static Future<void> initialize() async {
    poppinsFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Poppins-Regular.ttf'),
    );

    logoBytes = await rootBundle
        .load('assets/icons/terminal.png')
        .then((value) => value.buffer.asUint8List());
  }

  static pw.Text text(String content,
      {double fontSize = 12.0,
      pw.FontWeight? fontWeight,
      PdfColor? color,
      pw.TextAlign? align}) {
    return pw.Text(
      content,
      textAlign: align ?? pw.TextAlign.left,
      style: pw.TextStyle(
        font: poppinsFont,
        fontSize: fontSize,
        fontWeight: fontWeight ?? pw.FontWeight.normal,
        color: color ?? PdfColors.black,
      ),
    );
  }

  static List<pw.Widget> header(
      {required String reportTitle, required String subtitle}) {
    return [
      pw.Center(
        child: text(
          reportTitle,
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Center(
        child: text(
          subtitle,
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 14),
    ];
  }

  static pw.PageTheme pageBackground() {
    return pw.PageTheme(
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
    );
  }

  static pw.Widget footer({required String footerTitle}) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 5),
      child: pw.Column(
        children: [
          text(
            footerTitle,
            fontSize: 10,
            color: PdfColors.grey600,
          ),
          text(
            'Generated at - ${DateTime.now().toString()}',
            fontSize: 8,
            color: PdfColors.grey600,
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> generateExpenseTableGrpByDay(List<Expense2> expenses) {
    final groupedExpenses = <String, List<Expense2>>{};
    for (var expense in expenses) {
      if (!groupedExpenses.containsKey(expense.expenseType.name)) {
        groupedExpenses[expense.expenseType.name] = [];
      }
      groupedExpenses[expense.expenseType.name]?.add(expense);
    }

    return groupedExpenses.entries.map((entry) {
      final expenseType = entry.key;
      final expenseList = entry.value;
      final totalExpense =
          expenseList.fold(0.0, (sum, item) => sum + item.price);

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // _buildDashedLine(),
          pw.Table(
              // border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(1)
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          PdfHelper.text(
                            '$expenseType',
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          PdfHelper.text(
                            '${expenseList[0].expenseType.description}',
                          ),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: PdfHelper.text(
                        '₹ ${totalExpense}',
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ]),
          // _buildDashedLine(),
          pw.Table(
            // border: pw.TableBorder.all(),
            columnWidths: {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              ...expenseList.map((expense) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 1),
                        child: PdfHelper.text(expense.name, fontSize: 10),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 1),
                        child:
                            PdfHelper.text('₹${expense.price}', fontSize: 10),
                      ),
                    ],
                  )),
            ],
          ),
        ],
      );
    }).toList();
  }

  static List<pw.Widget> generateExpenseTableGrpByType(
      List<Expense2> expenses) {
    final groupedByDate = <DateTime, List<Expense2>>{};
    for (var expense in expenses) {
      DateTime expenseDate = expense.date;
      if (!groupedByDate.containsKey(expenseDate)) {
        groupedByDate[expenseDate] = [];
      }
      groupedByDate[expenseDate]?.add(expense);
    }

    final sortedGroupedByDate = Map.fromEntries(
      groupedByDate.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    return sortedGroupedByDate.entries.map((entry) {
      final expenseDay = entry.key;
      final expenseList = entry.value;
      final totalExpense =
          expenseList.fold(0.0, (sum, item) => sum + item.price);

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // _buildDashedLine(),
          pw.Table(
              // border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          PdfHelper.text(
                            DateFormat("d MMM yy").format(expenseDay),
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: PdfHelper.text(
                        '₹ ${totalExpense}',
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ]),
          // _buildDashedLine(),
          pw.Table(
            // border: pw.TableBorder.all(),
            columnWidths: {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              ...expenseList.map((expense) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 1),
                        child: PdfHelper.text(expense.name, fontSize: 10),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 1),
                        child:
                            PdfHelper.text('₹${expense.price}', fontSize: 10),
                      ),
                    ],
                  )),
            ],
          ),
        ],
      );
    }).toList();
  }

  static pw.Widget _buildDashedLine({
    double dashWidth = 5,
    double dashSpace = 3,
    double totalWidth = 500,
  }) {
    final dashCount = (totalWidth / (dashWidth + dashSpace)).floor();
    return pw.Wrap(
      spacing: dashSpace,
      children: List.generate(dashCount, (_) {
        return pw.Container(
          width: dashWidth,
          height: 1,
          color: PdfColors.grey700,
        );
      }),
    );
  }
}
