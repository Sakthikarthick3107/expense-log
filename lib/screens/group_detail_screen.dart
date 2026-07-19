import 'package:expense_log/models/account.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/group.dart';
import 'package:expense_log/services/accounts_service.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/widgets/group_expense_form.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:expense_log/widgets/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late UiService _uiService;
  late ExpenseService _expenseService;
  late AccountsService _accountsService;
  List<Account> accounts = [];
  Map<int, Expense2> deleteList = {};
  final ValueNotifier<DateTime> _selectedDateNotifier =
      ValueNotifier<DateTime>(DateTime.now());

  @override
  void initState() {
    super.initState();
    _uiService = Provider.of<UiService>(context, listen: false);
    _expenseService = Provider.of<ExpenseService>(context, listen: false);
    _accountsService = Provider.of<AccountsService>(context, listen: false);
    accounts = _accountsService.all;
    _selectedDateNotifier.addListener(() => setState(() => deleteList.clear()));
  }

  @override
  void dispose() {
    _selectedDateNotifier.dispose();
    super.dispose();
  }

  List<Expense2> _getDayExpenses() {
    final date = _selectedDateNotifier.value;
    return _expenseService.getExpenses().where((e) {
      return e.groupId == widget.group.id &&
          e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList();
  }

  Widget buildExpenseTile(Expense2 exp) {
    final accName = exp.accountId != null
        ? accounts
            .where((a) => a.id == exp.accountId)
            .fold<String>('', (prev, a) => a.name)
        : '';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: deleteList.isNotEmpty
              ? Icon(
                  deleteList.containsKey(exp.id)
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: deleteList.containsKey(exp.id)
                      ? Colors.green
                      : Colors.grey,
                )
              : CircleAvatar(
                  radius: 16,
                  child: Text(
                    exp.mappedUserName != null
                        ? exp.mappedUserName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
          title: Text(exp.name, style: const TextStyle(fontSize: 14)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${exp.expenseType.name}  •  ${exp.mappedUserName ?? 'Unassigned'}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              if (accName.isNotEmpty)
                Text(accName,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic)),
              if (exp.description != null && exp.description!.isNotEmpty)
                Text(exp.description!,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
          trailing: Text(
            '₹${exp.price.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: exp.price > 0 ? Colors.red : Colors.green,
            ),
          ),
          onTap: () {
            if (deleteList.isNotEmpty) {
              setState(() {
                if (deleteList.containsKey(exp.id)) {
                  deleteList.remove(exp.id);
                } else {
                  deleteList[exp.id] = exp;
                }
              });
            } else {
              _editExpense(exp);
            }
          },
          onLongPress: () {
            setState(() {
              if (!deleteList.containsKey(exp.id)) deleteList[exp.id] = exp;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: deleteList.isNotEmpty
                ? () {
                    WarningDialog.showWarning(
                      context: context,
                      title: 'Delete Selected',
                      message: 'Delete ${deleteList.length} expense(s)?',
                      onConfirmed: () {
                        _expenseService.deleteExpense(deleteList);
                        setState(() => deleteList.clear());
                      },
                    );
                  }
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  _selectedDateNotifier.value =
                      _selectedDateNotifier.value.subtract(const Duration(days: 1));
                },
                padding: const EdgeInsets.all(20.0),
                icon: const Icon(Icons.arrow_back_ios),
              ),
              ValueListenableBuilder<DateTime>(
                valueListenable: _selectedDateNotifier,
                builder: (context, selectedDate, _) {
                  return TextButton(
                    onPressed: () async {
                      DateTime pickDate = await _uiService.selectDate(
                          context, last: DateTime.now(), current: selectedDate);
                      _selectedDateNotifier.value = pickDate;
                    },
                    child: Text(
                      _uiService.displayDay(selectedDate),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700),
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
                    _selectedDateNotifier.value =
                        _selectedDateNotifier.value.add(const Duration(days: 1));
                  }
                },
                padding: const EdgeInsets.all(20.0),
                icon: const Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Expense2>('expense2Box').listenable(),
              builder: (context, Box<Expense2> box, _) {
                final dayExpenses = _getDayExpenses();
                if (dayExpenses.isEmpty) {
                  return Center(
                    child: Text(
                      'No expenses for ${_uiService.displayDay(_selectedDateNotifier.value)}\nTap + to add',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    ),
                  );
                }
                return ListView(
                  children: dayExpenses.map((e) => buildExpenseTile(e)).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExpense(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addExpense() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => GroupExpenseForm(
        group: widget.group,
        expenseDate: _selectedDateNotifier.value,
      ),
    );
    if (result == true) setState(() {});
  }

  Future<void> _editExpense(Expense2 expense) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => GroupExpenseForm(
        group: widget.group,
        expenseDate: expense.date,
        expense: expense,
      ),
    );
    if (result == true) setState(() {});
  }
}
