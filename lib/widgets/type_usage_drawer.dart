import 'package:expense_log/models/date_range.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/services/report_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:expense_log/widgets/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TypeUsageDrawer extends StatefulWidget {
  List<Expense2> expenses;
  TypeUsageDrawer({super.key, required this.expenses});

  @override
  State<TypeUsageDrawer> createState() => _TypeUsageDrawerState();
}

class _TypeUsageDrawerState extends State<TypeUsageDrawer> {
  DateRange getTypeUsageRange(List<Expense2> expenses) {
    if (expenses.isEmpty) {
      return DateRange(
        start: DateTime.now(),
        end: DateTime.now(),
      );
    }

    expenses.sort((a, b) => a.date.compareTo(b.date));
    return DateRange(
      start: expenses.first.date,
      end: expenses.last.date,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        if (widget.expenses.isEmpty) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            alignment: Alignment.center,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const Text(
              "No history available.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          );
        }

        final groupedExpenses = <DateTime, List<Expense2>>{};
        for (var expense in widget.expenses) {
          final date =
              DateTime(expense.date.year, expense.date.month, expense.date.day);
          groupedExpenses.putIfAbsent(date, () => []).add(expense);
        }

        final typeRange = getTypeUsageRange(widget.expenses);

        final sortedDates = groupedExpenses.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return Consumer<ReportService>(builder: (context, _reportService, _) {
          return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: FractionallySizedBox(
              heightFactor: 0.9,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () async {},
                        color: Theme.of(context).scaffoldBackgroundColor,
                        icon: const Icon(Icons.print),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          widget.expenses.first.expenseType.name +
                              ' - ₹' +
                              widget.expenses
                                  .fold(0.0, (act, exp) => act + exp.price)
                                  .toStringAsFixed(2),
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          WarningDialog.showWarning(
                              context: context,
                              title:
                                  'Type Report - ${widget.expenses.first.expenseType.name}',
                              message: 'Proceed to download report ',
                              onConfirmed: () async {
                                MessageWidget.showToast(
                                    context: context,
                                    message: 'Downloading in progress...');
                                await _reportService.prepareTypeReport(
                                    widget.expenses,
                                    [widget.expenses.first.expenseType.name],
                                    typeRange);
                              });
                        },
                        icon: const Icon(Icons.print),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      children: sortedDates.map((date) {
                        final expensesForDate = groupedExpenses[date]!;
                        return Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${date.day}/${date.month}/${date.year}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      '₹ ' +
                                          expensesForDate
                                              .fold(0.0,
                                                  (acc, exp) => acc + exp.price)
                                              .toStringAsFixed(2),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700),
                                    )
                                  ]),
                              ...expensesForDate.map(
                                (expense) => Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      expense.name,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      expense.price.toStringAsFixed(2),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
