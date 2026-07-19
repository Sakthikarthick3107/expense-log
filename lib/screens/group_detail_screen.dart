import 'package:expense_log/models/account.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/group.dart';
import 'package:expense_log/services/accounts_service.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/widgets/group_expense_form.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:expense_log/widgets/voice_input.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('Spends by User', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: DropdownButton<String>(
                      value: _chartDuration,
                      isDense: true,
                      underline: const SizedBox(),
                      onChanged: (v) => setState(() => _chartDuration = v!),
                      items: _durations.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
        ),
      ),
    );
  }

  Widget buildExpenseTile(Expense2 exp) {
    final accName = exp.accountId != null
        ? accounts.where((a) => a.id == exp.accountId).fold<String>('', (prev, a) => a.name)
        : '';
    final isDebit = exp.price > 0;
    final debitColor = isDebit ? Colors.red : Colors.green;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editExpense(exp),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: debitColor.withValues(alpha: 0.1),
              child: Icon(
                isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                size: 18,
                color: debitColor,
              ),
            ),
            title: Text(exp.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(exp.expenseType.name,
                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                    if (exp.mappedUserName != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                        ),
                        child: Text(exp.mappedUserName!,
                            style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ],
                ),
                if (accName.isNotEmpty)
                  Text(accName,
                      style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontStyle: FontStyle.italic)),
                if (exp.description != null && exp.description!.isNotEmpty)
                  Text(exp.description!,
                      style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('₹${exp.price.abs().toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: debitColor)),
                Text(isDebit ? 'Debit' : 'Credit',
                    style: TextStyle(fontSize: 10, color: debitColor.withValues(alpha: 0.7))),
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
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _selectedDateNotifier.value = _selectedDateNotifier.value.subtract(const Duration(days: 1)),
                    icon: const Icon(Icons.chevron_left),
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
                        MessageWidget.showToast(context: context, message: 'Cannot set expenses for future dates', status: 0);
                      } else {
                        _selectedDateNotifier.value = _selectedDateNotifier.value.add(const Duration(days: 1));
                      }
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Expense2>('expense2Box').listenable(),
                builder: (context, Box<Expense2> box, _) {
                  final dayExpenses = _getDayExpenses();
                  if (dayExpenses.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                              ),
                              child: Icon(Icons.receipt_long_outlined, size: 40, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No group expenses',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap + to add expense for\n${_uiService.displayDay(_selectedDateNotifier.value)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
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
          SpeedDialChild(
            child: const Icon(Icons.mic_none),
            label: 'Voice Input',
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            labelBackgroundColor: Theme.of(context).colorScheme.surface,
            onTap: () async {
              final sttPlugin = stt.SpeechToText();
              final available = await sttPlugin.initialize();
              if (!available) {
                MessageWidget.showToast(context: context, message: 'Speech not available', status: 0);
                return;
              }
              MessageWidget.showToast(context: context, message: 'Speak now...', status: 1);
              sttPlugin.listen(
                onResult: (result) {
                  if (result.finalResult) {
                    final parsed = parseVoiceInput(
                      result.recognizedWords,
                      _expenseService.getExpenseTypes().map((t) => t.name).toList(),
                      accountNames: accounts.map((a) => a.name).toList(),
                      groupMemberNames: widget.group.members,
                    );
                    showDialog<bool>(
                      context: context,
                      builder: (_) => GroupExpenseForm(
                        group: widget.group,
                        expenseDate: _selectedDateNotifier.value,
                        prefill: parsed,
                      ),
                    ).then((result) {
                      if (result == true) setState(() {});
                    });
                  }
                },
                listenOptions: stt.SpeechListenOptions(localeId: 'en_US'),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'New Expense',
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            labelBackgroundColor: Theme.of(context).colorScheme.surface,
            onTap: () => _addExpense(),
          ),
        ],
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
