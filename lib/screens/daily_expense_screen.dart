import 'package:expense_log/models/account.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/screens/home_screen.dart';
import 'package:expense_log/services/accounts_service.dart';
import 'package:expense_log/services/audit_log_service.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/report_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/widgets/expense_form.dart';
import 'package:expense_log/widgets/info_dialog.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:expense_log/widgets/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'package:expense_log/widgets/voice_input.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class DailyExpenseScreen extends StatefulWidget {
  const DailyExpenseScreen({super.key});

  @override
  State<DailyExpenseScreen> createState() => _DailyExpenseScreenState();
}

class _DailyExpenseScreenState extends State<DailyExpenseScreen> {
  late UiService _uiService;
  late ExpenseService _expenseService;
  late SettingsService _settingsService;
  late ReportService _reportService;
  late AccountsService _accountsService;
  String? expenseType;
  final ValueNotifier<DateTime> _selectedDateNotifier =
      ValueNotifier<DateTime>(DateTime.now());
  double totalExpense = 0.0;
  Map<int, Expense2> deleteList = {};
  late Map<String, double> _metricsData = {};
  bool groupByType = false;
  List<Account> accounts = [];
  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _uiService = Provider.of<UiService>(context, listen: false);
    _expenseService = Provider.of<ExpenseService>(context, listen: false);
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _reportService = Provider.of<ReportService>(context, listen: false);
    _accountsService = Provider.of<AccountsService>(context, listen: false);
    setState(() {
      accounts = _accountsService.all;
    });
    totalExpense =
        _expenseService.selectedDayTotalExpense(_selectedDateNotifier.value);
    _metricsData = _expenseService.getMetrics('This month', 'By type', []);
    _selectedDateNotifier.addListener(() {
      setState(() {
        _metricsData = _expenseService.getMetrics('This month', 'By type', []);
        totalExpense = _expenseService
            .selectedDayTotalExpense(_selectedDateNotifier.value);
        deleteList.clear();
      });
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _speech.cancel();
    _selectedDateNotifier.dispose();
    super.dispose();
  }

  Widget buildExpenseTile(Expense2 expOfDay, {bool showType = true}) {
    var accId = expOfDay.accountId;
    var accName = accId != null ? accounts.firstWhere((x) => x.id == expOfDay.accountId).name:'';
    final isGroupExpense = expOfDay.groupId != null;
    final isDebit = expOfDay.price > 0;
    final debitColor = isDebit ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (deleteList.isNotEmpty) {
            setState(() {
              if (deleteList.containsKey(expOfDay.id)) {
                deleteList.remove(expOfDay.id);
              } else {
                deleteList[expOfDay.id] = expOfDay;
              }
            });
          } else {
            final result = await showDialog<bool>(
              context: context,
              builder: (context) => ExpenseForm(
                expenseDate: _selectedDateNotifier.value,
                expense: expOfDay,
              ),
            );
            if (result == true) {
              setState(() {
                totalExpense = _expenseService
                    .selectedDayTotalExpense(_selectedDateNotifier.value);
                _metricsData =
                    _expenseService.getMetrics('This month', 'By type', []);
              });
            }
          }
        },
        onLongPress: () {
          setState(() {
            if (!deleteList.containsKey(expOfDay.id)) {
              deleteList[expOfDay.id] = expOfDay;
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: ListTile(
            leading: deleteList.isNotEmpty
                ? Icon(
                    deleteList.containsKey(expOfDay.id)
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: deleteList.containsKey(expOfDay.id)
                        ? debitColor
                        : Colors.grey,
                  )
                : CircleAvatar(
                    backgroundColor: debitColor.withValues(alpha: 0.1),
                    child: Icon(
                      isGroupExpense ? Icons.group : (isDebit ? Icons.arrow_downward : Icons.arrow_upward),
                      size: 18,
                      color: debitColor,
                    ),
                  ),
            title: Text(
              expOfDay.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showType)
                  Text(
                    expOfDay.expenseType.name,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                if (isGroupExpense && expOfDay.mappedUserName != null)
                  Row(
                    children: [
                      Icon(Icons.group, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                      const SizedBox(width: 3),
                      Text(
                        '${expOfDay.mappedUserName}',
                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${expOfDay.price.abs().toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: debitColor),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isDebit ? 'Debit' : 'Credit',
                      style: TextStyle(fontSize: 10, color: debitColor.withValues(alpha: 0.7)),
                    ),
                    if (accName.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(width: 3, height: 3, decoration: BoxDecoration(color: Colors.grey[400]!, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(
                        accName,
                        style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            if (_selectedDateNotifier.value.year == DateTime.now().year &&
                _selectedDateNotifier.value.month == DateTime.now().month &&
                _selectedDateNotifier.value.day == DateTime.now().day) {
              MessageWidget.showToast(
                  context: context,
                  message: 'Cannot able to set daily expense for future dates',
                  status: 0);
            } else {
              setState(() {
                _selectedDateNotifier.value =
                    _selectedDateNotifier.value.add(const Duration(days: 1));
              });
            }
          } else if (details.primaryVelocity! > 0) {
            setState(() {
              _selectedDateNotifier.value =
                  _selectedDateNotifier.value.subtract(const Duration(days: 1));
            });
          }
        },
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedDateNotifier.value = _selectedDateNotifier
                                .value
                                .subtract(const Duration(days: 1));
                          });
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      ValueListenableBuilder<DateTime>(
                        valueListenable: _selectedDateNotifier,
                        builder: (context, selectedDate, _) {
                          return TextButton(
                            onPressed: () async {
                              DateTime pickDate = await _uiService.selectDate(
                                  context,
                                  last: DateTime.now(),
                                  current: _selectedDateNotifier.value);
                              setState(() {
                                _selectedDateNotifier.value = pickDate;
                              });
                            },
                            child: Text(
                              _uiService.displayDay(_selectedDateNotifier.value),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        onPressed: () {
                          if (_selectedDateNotifier.value.year == DateTime.now().year &&
                              _selectedDateNotifier.value.month == DateTime.now().month &&
                              _selectedDateNotifier.value.day == DateTime.now().day) {
                            MessageWidget.showToast(
                                context: context,
                                message: 'Cannot set expenses for future dates',
                                status: 0);
                          } else {
                            setState(() {
                              _selectedDateNotifier.value = _selectedDateNotifier
                                  .value
                                  .add(const Duration(days: 1));
                            });
                          }
                        },
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() async {
                              await _settingsService.setGrpExpByType(!_settingsService.groupExpByType());
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: _settingsService.groupExpByType()
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.category,
                                  size: 16,
                                  color: _settingsService.groupExpByType()
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Group by Type",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _settingsService.groupExpByType() ? FontWeight.w600 : FontWeight.normal,
                                    color: _settingsService.groupExpByType()
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ValueListenableBuilder(
                          valueListenable: _selectedDateNotifier,
                          builder: (context, date, _) {
                            if (deleteList.isNotEmpty) {
                              return ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                onPressed: () {
                                  WarningDialog.showWarning(
                                    context: context,
                                    title: 'Delete Expenses',
                                    message: 'Delete selected ${deleteList.length} expenses?',
                                    onConfirmed: () {
                                      _expenseService.deleteExpense(deleteList);
                                      setState(() {
                                        deleteList.clear();
                                        totalExpense = _expenseService.selectedDayTotalExpense(_selectedDateNotifier.value);
                                        _metricsData = _expenseService.getMetrics('This month', 'By type', []);
                                      });
                                    },
                                    onCancelled: () {
                                      setState(() {
                                        deleteList.clear();
                                        totalExpense = _expenseService.selectedDayTotalExpense(_selectedDateNotifier.value);
                                        _metricsData = _expenseService.getMetrics('This month', 'By type', []);
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: Text('Delete (${deleteList.length})'),
                              );
                            }
                            final isTotalDebit = totalExpense > 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isTotalDebit
                                    ? Colors.red.withValues(alpha: 0.06)
                                    : Colors.green.withValues(alpha: 0.06),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isTotalDebit ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isTotalDebit ? Colors.red : Colors.green,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isTotalDebit ? 'Total Debit' : 'Total Credit',
                                        style: TextStyle(fontSize: 10, color: isTotalDebit ? Colors.red : Colors.green, fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        '₹ ${totalExpense.abs().toStringAsFixed(2)}',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isTotalDebit ? Colors.red : Colors.green),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
                child: ValueListenableBuilder(
              valueListenable: Hive.box<Expense2>('expense2Box').listenable(),
              builder: (context, Box<Expense2> box, _) {
                final expenseOfTheDate = _expenseService
                    .getExpensesOfTheDay(_selectedDateNotifier.value);
                if (expenseOfTheDate.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/add-note.json',
                            width: 180,
                            height: 180,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to create expense for\n${_uiService.displayDay(_selectedDateNotifier.value)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (_settingsService.groupExpByType()) {
                  // Group by type
                  Map<String, List<Expense2>> grpWithType = {};
                  for (var expense in expenseOfTheDate) {
                    final type = expense.expenseType.name;
                    if (grpWithType.containsKey(type)) {
                      grpWithType[type]!.add(expense);
                    } else {
                      grpWithType[type] = [expense];
                    }
                  }

                  return ListView(
                    children: grpWithType.entries.expand((entry) {
                      final type = entry.key;
                      final expenses = entry.value;
                      double typeCredit = expenses.where((x)=> (x.price <= 0)).fold<double>(0.0, (sum, e) => sum + e.price);
                      double typeDebit = expenses.where((x)=> (x.price > 0)).fold<double>(0.0, (sum, e) => sum + e.price);
                      return [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Card(
                            margin: EdgeInsets.zero,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.folder_special_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        type,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      if (typeCredit != 0) ...[
                                        Icon(Icons.arrow_upward, color: Colors.green, size: 14),
                                        const SizedBox(width: 2),
                                        Text(
                                          '₹${typeCredit.abs().toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      if (typeDebit != 0) ...[
                                        Icon(Icons.arrow_downward, color: Colors.red, size: 14),
                                        const SizedBox(width: 2),
                                        Text(
                                          '₹${typeDebit.abs().toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ...expenses
                            .map((expOfDay) =>
                                buildExpenseTile(expOfDay, showType: false))
                            .toList(),
                      ];
                    }).toList(),
                  );
                } else {
                  // Normal flat list
                  return ListView(
                    children: expenseOfTheDate
                        .map((expOfDay) => buildExpenseTile(expOfDay))
                        .toList(),
                  );
                }
              },
            )),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        activeBackgroundColor: Colors.redAccent,
        spacing: 10,
        spaceBetweenChildren: 10,
        childrenButtonSize: const Size(45, 45),
        buttonSize: const Size(50, 50),
        overlayOpacity: 0.1,
        elevation: 8.0,
        children: [
          if (_expenseService
              .getExpensesOfTheDay(_selectedDateNotifier.value)
              .isNotEmpty)
            SpeedDialChild(
              child: const Icon(Icons.print),
              label: 'Daily Expense Report',
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              labelBackgroundColor: Theme.of(context).colorScheme.surface,
              onTap: () {
                WarningDialog.showWarning(
                    context: context,
                    title: 'Daily Expense Report',
                    message:
                        'Proceed to download report for ${_uiService.displayDay(_selectedDateNotifier.value)}',
                    onConfirmed: () async {
                      MessageWidget.showToast(
                          context: context,
                          message: 'Downloading in progress...');
                      await _reportService.prepareDailyExpenseReport(
                        _expenseService
                            .getExpensesOfTheDay(_selectedDateNotifier.value),
                      );
                    });
              },
            ),
          SpeedDialChild(
            child: const Icon(Icons.copy),
            label: 'Copy expense from other day',
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            labelBackgroundColor: Theme.of(context).colorScheme.surface,
            onTap: () async {
              DateTime? copyFromDate = await _uiService.selectDate(context,
                  last: DateTime.now(),
                  current: _selectedDateNotifier.value,
                  title: 'Select a date to copy expenses');
              WarningDialog.showWarning(
                  context: context,
                  title: 'Confirm',
                  message: 'Are you sure to copy expenses of '
                      '${_uiService.displayDay(copyFromDate)} '
                      'to ${_uiService.displayDay(_selectedDateNotifier.value)}',
                  onConfirmed: () async {
                    if (copyFromDate != null) {
                      List<String> getExceedList = [];
                      int createCopiedExpenses =
                          await _expenseService.copyAndSaveExpenses(
                              copyFromDate: copyFromDate,
                              pasteToDate: _selectedDateNotifier.value,
                              exceedList: getExceedList);
                      if (createCopiedExpenses == 0) {
                        setState(() {
                          totalExpense =
                              _expenseService.selectedDayTotalExpense(
                                  _selectedDateNotifier.value);
                          _metricsData = _expenseService
                              .getMetrics<String>('This month', 'By type', []);
                        });
                        MessageWidget.showToast(
                            context: context,
                            message: 'Copied successfully',
                            status: 1);
                        if (getExceedList.isNotEmpty) {
                          InfoDialog.showInfo(
                              context: context,
                              content: [Text(getExceedList.join('\n'))]);
                          AuditLogService.writeLog(
                              'Limit Summary - ${getExceedList.join(',')}');
                        }
                      } else if (createCopiedExpenses == -1) {
                        MessageWidget.showToast(
                            context: context,
                            message: 'No expenses in the selected date!',
                            status: 0);
                      } else if (createCopiedExpenses > 0) {
                        MessageWidget.showToast(
                            context: context,
                            message:
                                '${createCopiedExpenses} expenses exceeded their limits and were skipped.');
                      } else if (createCopiedExpenses == -2) {
                        MessageWidget.showToast(
                            context: context,
                            message: 'Error when copying expenses',
                            status: 0);
                      }
                    }
                  });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.mic_none),
            label: 'Voice Input',
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            labelBackgroundColor: Theme.of(context).colorScheme.surface,
            onTap: () async {
              final available = await _speech.initialize();
              if (!available) {
                MessageWidget.showToast(context: context, message: 'Speech not available on this device', status: 0);
                return;
              }
              MessageWidget.showToast(context: context, message: 'Speak now...', status: 1);
              _speech.listen(
                onResult: (result) {
                  if (result.finalResult) {
                    final parsed = parseVoiceInput(
                      result.recognizedWords,
                      _expenseService.getExpenseTypes().map((t) => t.name).toList(),
                      accountNames: accounts.map((a) => a.name).toList(),
                    );
                    final getTypes = _expenseService.getExpenseTypes();
                    if (getTypes.isNotEmpty) {
                      showDialog<bool>(
                        context: context,
                        builder: (context) => ExpenseForm(
                          expenseDate: _selectedDateNotifier.value,
                          prefill: parsed,
                        ),
                      ).then((result) {
                        if (result == true) {
                          setState(() {
                            totalExpense = _expenseService
                                .selectedDayTotalExpense(_selectedDateNotifier.value);
                            _metricsData =
                                _expenseService.getMetrics('This month', 'By type', []);
                          });
                        }
                      });
                    }
                  }
                },
                listenOptions: stt.SpeechListenOptions(localeId: 'en_US'),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Create New Expense',
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            labelBackgroundColor: Theme.of(context).colorScheme.surface,
            onTap: () async {
              final getTypes = _expenseService.getExpenseTypes();
              if (getTypes.isNotEmpty) {
                final result = await showDialog<bool>(
                    context: context,
                    builder: (context) =>
                        ExpenseForm(expenseDate: _selectedDateNotifier.value));
                if (result == true) {
                  setState(() {
                    totalExpense = _expenseService
                        .selectedDayTotalExpense(_selectedDateNotifier.value);
                    _metricsData =
                        _expenseService.getMetrics('This month', 'By type', []);
                  });
                }
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const HomeScreen(initialIndex: 1)));
                MessageWidget.showToast(
                    context: context,
                    message:
                        'Create your expense type for adding your expense and keep track of it');
              }
            },
          ),
        ],
      ),
    );
  }
}
