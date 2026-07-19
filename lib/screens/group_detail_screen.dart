import 'package:expense_log/models/account.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/group.dart';
import 'package:expense_log/services/accounts_service.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/widgets/group_expense_form.dart';
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

  @override
  void initState() {
    super.initState();
    _uiService = Provider.of<UiService>(context, listen: false);
    _expenseService = Provider.of<ExpenseService>(context, listen: false);
    _accountsService = Provider.of<AccountsService>(context, listen: false);
    accounts = _accountsService.all;
  }

  List<Expense2> _getGroupExpenses() {
    final allExpenses = _expenseService.getExpenses();
    return allExpenses.where((e) => e.groupId == widget.group.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    final groupExpenses = _getGroupExpenses();
    final totalDebit = groupExpenses
        .where((e) => e.price > 0)
        .fold(0.0, (sum, e) => sum + e.price);
    final totalCredit = groupExpenses
        .where((e) => e.price <= 0)
        .fold(0.0, (sum, e) => sum + e.price.abs());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          if (groupExpenses.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: deleteList.isNotEmpty
                  ? () {
                      WarningDialog.showWarning(
                        context: context,
                        title: 'Delete Selected',
                        message:
                            'Delete ${deleteList.length} expense(s)?',
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
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Expense2>('expense2Box').listenable(),
        builder: (context, Box<Expense2> box, _) {
          final expenses = _getGroupExpenses();
          if (expenses.isEmpty) {
            return const Center(
              child: Text('No expenses in this group'),
            );
          }
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Total Debit',
                            style: TextStyle(fontSize: 12, color: Colors.red)),
                        Text('₹${totalDebit.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Total Credit',
                            style:
                                TextStyle(fontSize: 12, color: Colors.green)),
                        Text('₹${totalCredit.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
              ...expenses.map((exp) {
                final accName = exp.accountId != null
                    ? accounts
                        .where((a) => a.id == exp.accountId)
                        .fold<String>('', (prev, a) => a.name)
                    : '';
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                              radius: 18,
                              child: Text(
                                exp.mappedUserName != null
                                    ? exp.mappedUserName![0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                      title: Text(exp.name,
                          style: const TextStyle(fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${exp.expenseType.name}  •  ${exp.mappedUserName ?? 'Unassigned'}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                          if (accName.isNotEmpty)
                            Text(accName,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic)),
                          if (exp.description != null &&
                              exp.description!.isNotEmpty)
                            Text(exp.description!,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[500])),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${exp.price.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: exp.price > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                exp.price > 0
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                size: 12,
                                color: exp.price > 0
                                    ? Colors.red
                                    : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _uiService.displayDay(exp.date),
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ],
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
                          if (!deleteList.containsKey(exp.id)) {
                            deleteList[exp.id] = exp;
                          }
                        });
                      },
                    ),
                  ),
                );
              }),
            ],
          );
        },
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
        expenseDate: DateTime.now(),
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
