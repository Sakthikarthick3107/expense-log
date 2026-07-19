import 'package:expense_log/models/account.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/group.dart';
import 'package:expense_log/services/accounts_service.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/widgets/group_expense_form.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:fl_chart/fl_chart.dart';
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
  final ValueNotifier<DateTime> _selectedDateNotifier =
      ValueNotifier<DateTime>(DateTime.now());

  static const List<String> _durations = [
    'This week', 'Last week', 'This month', 'Last month'
  ];
  String _chartDuration = 'This week';

  @override
  void initState() {
    super.initState();
    _uiService = Provider.of<UiService>(context, listen: false);
    _expenseService = Provider.of<ExpenseService>(context, listen: false);
    _accountsService = Provider.of<AccountsService>(context, listen: false);
    accounts = _accountsService.all;
    _selectedDateNotifier.addListener(() => setState(() {}));
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

  Map<String, double> _getPerUserChartData() {
    final range = _uiService.getDateRange(_chartDuration);
    if (range == null) return {};
    final expenses = _expenseService.getExpenses().where((e) {
      return e.groupId == widget.group.id &&
          !e.date.isBefore(range.start) &&
          e.date.isBefore(range.end.add(const Duration(days: 1)));
    }).toList();
    Map<String, double> perUser = {};
    for (final e in expenses) {
      final user = e.mappedUserName ?? 'Unassigned';
      perUser[user] = (perUser[user] ?? 0) + e.price.abs();
    }
    return perUser;
  }

  Widget _buildChart() {
    final data = _getPerUserChartData();
    if (data.isEmpty) return const SizedBox.shrink();
    final maxY = data.values.reduce((a, b) => a > b ? a : b);
    final interval = (maxY / 4).ceilToDouble().clamp(1.0, double.infinity);
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.teal, Colors.pink];
    int ci = 0;
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spends by User', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              DropdownButton<String>(
                value: _chartDuration,
                isDense: true,
                onChanged: (v) => setState(() => _chartDuration = v!),
                items: _durations.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 11)))).toList(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY + interval,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: interval,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true,
                      getTitlesWidget: (v, _) {
                        final keys = data.keys.toList();
                        final i = v.toInt();
                        if (i < 0 || i >= keys.length) return const SizedBox.shrink();
                        return Text(keys[i], style: const TextStyle(fontSize: 9));
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: data.entries.map((e) {
                  final c = colors[ci++ % colors.length];
                  return BarChartGroupData(x: data.keys.toList().indexOf(e.key), barRods: [
                    BarChartRodData(toY: e.value, color: c, width: 20, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  ]);
                }).toList(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (g, _, r, __) => BarTooltipItem('₹${r.toY.toStringAsFixed(0)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildExpenseTile(Expense2 exp) {
    final accName = exp.accountId != null
        ? accounts.where((a) => a.id == exp.accountId).fold<String>('', (prev, a) => a.name)
        : '';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _editExpense(exp),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: exp.price > 0
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  child: Icon(
                    exp.price > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 14,
                    color: exp.price > 0 ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exp.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(exp.expenseType.name,
                              style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                          const SizedBox(width: 6),
                          CircleAvatar(
                            radius: 6,
                            child: Text(
                              exp.mappedUserName != null ? exp.mappedUserName![0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(exp.mappedUserName ?? '',
                              style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                        ],
                      ),
                      if (accName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(accName,
                              style: TextStyle(fontSize: 9, color: Colors.grey[400], fontStyle: FontStyle.italic)),
                        ),
                      if (exp.description != null && exp.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(exp.description!,
                              style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${exp.price.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold,
                            color: exp.price > 0 ? Colors.red : Colors.green)),
                    Text(exp.price > 0 ? 'Debit' : 'Credit',
                        style: TextStyle(fontSize: 8, color: Colors.grey[500])),
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
      appBar: AppBar(
        title: Text(widget.group.name),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            if (_selectedDateNotifier.value.year == DateTime.now().year &&
                _selectedDateNotifier.value.month == DateTime.now().month &&
                _selectedDateNotifier.value.day == DateTime.now().day) {
              MessageWidget.showToast(context: context, message: 'Cannot set expenses for future dates', status: 0);
            } else {
              _selectedDateNotifier.value = _selectedDateNotifier.value.add(const Duration(days: 1));
            }
          } else if (details.primaryVelocity! > 0) {
            _selectedDateNotifier.value = _selectedDateNotifier.value.subtract(const Duration(days: 1));
          }
        },
        child: Column(
          children: [
            _buildChart(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _selectedDateNotifier.value = _selectedDateNotifier.value.subtract(const Duration(days: 1)),
                  padding: const EdgeInsets.all(8.0),
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                ValueListenableBuilder<DateTime>(
                  valueListenable: _selectedDateNotifier,
                  builder: (context, selectedDate, _) {
                    return TextButton(
                      onPressed: () async {
                        final pickDate = await _uiService.selectDate(context, last: DateTime.now(), current: selectedDate);
                        _selectedDateNotifier.value = pickDate;
                      },
                      child: Text(
                        _uiService.displayDay(selectedDate),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    );
                  },
                ),
                IconButton(
                  onPressed: () {
                    if (_selectedDateNotifier.value.year == DateTime.now().year &&
                        _selectedDateNotifier.value.month == DateTime.now().month &&
                        _selectedDateNotifier.value.day == DateTime.now().day) {
                      MessageWidget.showToast(context: context, message: 'Cannot set expenses for future dates', status: 0);
                    } else {
                      _selectedDateNotifier.value = _selectedDateNotifier.value.add(const Duration(days: 1));
                    }
                  },
                  padding: const EdgeInsets.all(8.0),
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
