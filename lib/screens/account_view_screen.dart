import 'package:expense_log/screens/sms_review_page.dart';
import 'package:expense_log/services/report_service.dart';
import 'package:expense_log/services/sms_sync_service.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../models/account.dart';
import '../services/accounts_service.dart';
import 'account_create_screen.dart';
import '../models/expense2.dart';
import '../services/expense_service.dart';

class AccountViewScreen extends StatefulWidget {
  final Account account;
  const AccountViewScreen({Key? key, required this.account}) : super(key: key);

  @override
  State<AccountViewScreen> createState() => _AccountViewScreenState();
}

class _AccountViewScreenState extends State<AccountViewScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  late SmsSyncService smsSyncService;

  void initState() {
    super.initState();
    smsSyncService = Provider.of<SmsSyncService>(context, listen: false);
  }

  Future<void> _printReport(BuildContext context) async {
    final reportService = Provider.of<ReportService>(context, listen: false);

    final expenses = await _loadExpenses();

    await reportService.prepareAccountExpenseReport(
        widget.account, expenses, _fromDate, _toDate);
    MessageWidget.showToast(
        context: context, message: "Report generated successfully");
  }

  Future<void> _edit(BuildContext ctx) async {
    final res = await Navigator.push(
        ctx,
        MaterialPageRoute(
            builder: (_) => AccountCreateScreen(editing: widget.account)));
    if (res == true)
      ScaffoldMessenger.of(ctx)
          .showSnackBar(const SnackBar(content: Text('Account updated')));
  }

  Future<void> _delete(BuildContext ctx) async {
    final ok = await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            title: const Text('Delete account'),
            content: Text(
                'Delete account "${widget.account.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (ok) {
      final svc = Provider.of<AccountsService>(ctx, listen: false);
      await svc.delete(widget.account.id);
      Navigator.pop(ctx, true);
    }
  }

  Future<void> _openDateFilter() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 5); // limit

    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: now,
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)), end: now),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  Future<List<Expense2>> _loadExpenses() async {
    Box<Expense2> box;
    if (Hive.isBoxOpen('expense2Box')) {
      box = Hive.box<Expense2>('expense2Box');
    } else {
      box = await Hive.openBox<Expense2>('expense2Box');
    }

    final aId = widget.account.id?.toString();
    var items = box.values.where((e) {
      final ea = e.accountId;
      return ea != null && ea.toString() == aId;
    }).toList();

    if (_fromDate != null && _toDate != null) {
      items = items.where((e) {
        final ed = DateTime(e.date.year, e.date.month, e.date.day);
        final from =
            DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
        final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
        return ed.compareTo(from) >= 0 && ed.compareTo(to) <= 0;
      }).toList();
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  String _fmtDate(DateTime d) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Account Details'),
            if (_fromDate != null && _toDate != null)
              Text(
                '${_fmtDate(_fromDate!)} to ${_fmtDate(_toDate!)}',
                style: const TextStyle(fontSize: 10),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _openDateFilter,
          ),
          IconButton(
              onPressed: () {
                _printReport(context);
              },
              icon: const Icon(Icons.print)),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _edit(context),
          ),
          // IconButton(
          //   icon: const Icon(Icons.delete),
          //   onPressed: () => _delete(context),
          // ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(children: [
                CircleAvatar(
                    child: Text(widget.account.name.isNotEmpty
                        ? widget.account.name[0].toUpperCase()
                        : 'A')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.account.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(widget.account.code,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 6),
                        Text(widget.account.description ?? '-',
                            style: Theme.of(context).textTheme.bodySmall),
                      ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Created', style: Theme.of(context).textTheme.bodySmall),
                  Text(_fmtDate(widget.account.createdAt),
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text('Updated', style: Theme.of(context).textTheme.bodySmall),
                  Text(
                      widget.account.updatedAt != null
                          ? _fmtDate(widget.account.updatedAt!)
                          : '-',
                      style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.sync),
                label: const Text("Sync SMS"),
                onPressed: () async {
                  final txns = await smsSyncService.sync(widget.account);

                  if (txns.isNotEmpty) {
                    MessageWidget.showToast(
                      context: context,
                      message: "Transactions found in SMS",
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SmsReviewPage(
                          account: widget.account,
                          txns: txns,
                        ),
                      ),
                    );
                  } else {
                    MessageWidget.showToast(
                      context: context,
                      message: "No new transactions found in SMS",
                    );
                  }
                },
              )
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Expense2>>(
            future: _loadExpenses(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox();
              final items = snap.data!;
              final overallTotal =
                  items.fold<double>(0.0, (s, e) => s + e.price);
              final overallDebit = items
                  .where((x) => (x.price > 0))
                  .fold<double>(0.0, (s, e) => s + e.price);
              final overallCredit = items
                  .where((x) => (x.price <= 0))
                  .fold<double>(0.0, (s, e) => s + e.price);

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transactions count
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transactions',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('${items.length}',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),

                    // Total Debit (Spent)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Debit (Spent)',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          '₹ ${overallDebit.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: Colors.red),
                        ),
                      ],
                    ),

                    // Total Credit (Received)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Credit (Received)',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          '₹ ${overallCredit.abs().toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          FutureBuilder<List<Expense2>>(
            future: _loadExpenses(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox();
              final items = snap.data!;
              if (items.isEmpty) return const SizedBox();
              final Map<String, List<Expense2>> typeGrouped = {};

              for (final e in items) {
                final typeName = (e.expenseType?.name ?? "Unknown");

                typeGrouped.putIfAbsent(typeName, () => []).add(e);
              }
              final sortedTypeGrouped = Map.fromEntries(
                  typeGrouped.entries.toList()
                    ..sort((a, b) =>
                        a.key.toLowerCase().compareTo(b.key.toLowerCase())));

              return SizedBox(
                height: 75,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sortedTypeGrouped.keys.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final type = sortedTypeGrouped.keys.elementAt(index);
                    final list = sortedTypeGrouped[type] ?? [];
                    final debitTotal = list
                        .where((x) => x.price > 0)
                        .fold<double>(0.0, (s, e) => s + e.price);
                    final creditTotal = list
                        .where((x) => x.price < 0)
                        .fold<double>(0.0, (s, e) => s + e.price.abs());

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(type,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(fontWeight: FontWeight.bold)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_upward,
                                      size: 12,
                                      color: Colors.green,
                                    ),
                                    Text(
                                      "₹ ${creditTotal.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_downward,
                                      size: 12,
                                      color: Colors.red,
                                    ),
                                    Text(
                                      "₹ ${debitTotal.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<List<Expense2>>(
              future: _loadExpenses(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.isEmpty) {
                  return const Center(
                      child: Text('No transactions for this account'));
                }
                final items = snap.data!;

                // Group by actual DateTime (yyyy-mm-dd without time)
                final Map<DateTime, List<Expense2>> grouped = {};
                for (final e in items) {
                  final dateOnly =
                      DateTime(e.date.year, e.date.month, e.date.day);
                  grouped.putIfAbsent(dateOnly, () => []).add(e);
                }

                // Sort dates descending
                final List<DateTime> dates = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                // compute overall totals
                final overallTotal =
                    items.fold<double>(0.0, (s, ex) => s + ex.price);
                // Use a single list: first item shows summary, following items are date groups (no cards)
                return ListView.builder(
                  itemCount: dates.length + 1,
                  padding: const EdgeInsets.only(bottom: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // summary row
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Text('Transactions: ${items.length}', style: Theme.of(context).textTheme.bodyLarge),
                            // Text('Total Paid: ${overallTotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      );
                    }

                    final date = dates[index - 1];
                    final dayItems = grouped[date]!;
                    final dayTotal =
                        dayItems.fold<double>(0.0, (s, ex) => s + ex.price);
                    bool isDayDebit = dayTotal > 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // date header
                          Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6.0, horizontal: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _fmtDate(date),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    '${isDayDebit ? "- " : "+ "}₹ ${dayTotal.abs().toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: isDayDebit
                                              ? Colors.red
                                              : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              )),
                          const Divider(height: 1),
                          // transactions for the day (plain background)
                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: dayItems.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 0.1),
                            itemBuilder: (context, i) {
                              final e = dayItems[i];
                              final typeName = (e.expenseType is String)
                                  ? e.expenseType
                                  : (e.expenseType?.name ?? '');
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 0),
                                title: Text(e.name,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                                subtitle: Text(
                                    '$typeName • ${e.date.toLocal().hour.toString().padLeft(2, '0')}:${e.date.toLocal().minute.toString().padLeft(2, '0')} ${e.date.hour >= 12 ? 'PM' : 'AM'}'),
                                trailing: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${e.price > 0 ? '- ' : '+ '}${e.price.abs().toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            e.price > 0
                                                ? Icons.arrow_downward
                                                : Icons.arrow_upward,
                                            size: 12,
                                            color: e.price > 0
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            e.price > 0 ? 'Debit' : 'Credit',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
