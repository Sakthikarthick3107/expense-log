import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../models/account.dart';
import '../services/accounts_service.dart';
import 'account_create_screen.dart';
import '../models/expense2.dart';
import '../services/expense_service.dart';

class AccountViewScreen extends StatelessWidget {
  final Account account;
  const AccountViewScreen({Key? key, required this.account}) : super(key: key);

  Future<void> _edit(BuildContext ctx) async {
    final res = await Navigator.push(ctx, MaterialPageRoute(builder: (_) => AccountCreateScreen(editing: account)));
    if (res == true) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Account updated')));
  }

  Future<void> _delete(BuildContext ctx) async {
    final ok = await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            title: const Text('Delete account'),
            content: Text('Delete account "${account.name}"? This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (ok) {
      final svc = Provider.of<AccountsService>(ctx, listen: false);
      await svc.delete(account.id);
      Navigator.pop(ctx, true);
    }
  }

  Future<List<Expense2>> _loadExpenses() async {
    // try to use opened box if available, otherwise open
    Box<Expense2> box;
    if (Hive.isBoxOpen('expense2Box')) {
      box = Hive.box<Expense2>('expense2Box');
    } else {
      box = await Hive.openBox<Expense2>('expense2Box');
    }
    final aId = account.id?.toString();
    final items = box.values.where((e) {
      final ea = e.accountId;
      return ea != null && ea.toString() == aId;
    }).toList();
    // sort newest first
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  String _fmtDate(DateTime d) => d.toLocal().toString().split(' ').first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
        actions: [
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(children: [
                CircleAvatar(child: Text(account.name.isNotEmpty ? account.name[0].toUpperCase() : 'A')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(account.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(account.code, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Text(account.description ?? '-', style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Created', style: Theme.of(context).textTheme.bodySmall),
                  Text(_fmtDate(account.createdAt), style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text('Updated', style: Theme.of(context).textTheme.bodySmall),
                  Text(account.updatedAt != null ? _fmtDate(account.updatedAt!) : '-', style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 8),
          FutureBuilder<List<Expense2>>(
      future: _loadExpenses(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final items = snap.data!;
        final overallTotal = items.fold<double>(0.0, (s, e) => s + e.price);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transactions: ${items.length}', style: Theme.of(context).textTheme.bodyLarge),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total Spent', style: Theme.of(context).textTheme.bodySmall),
                  Text('₹ ${overallTotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge),
                  ],
              ),
            ],
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
                  return const Center(child: Text('No transactions for this account'));
                }
                final items = snap.data!;

                // Group by date string (yyyy-mm-dd)
                final Map<String, List<Expense2>> grouped = {};
                for (final e in items) {
                  final key = _fmtDate(e.date);
                  grouped.putIfAbsent(key, () => []).add(e);
                }

                // Sort dates descending
                final List<String> dates = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                // compute overall totals
                final overallTotal = items.fold<double>(0.0, (s, ex) => s + ex.price);
                // Use a single list: first item shows summary, following items are date groups (no cards)
                return ListView.builder(
                  itemCount: dates.length + 1,
                  padding: const EdgeInsets.only(bottom: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // summary row
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
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
                    final dayTotal = dayItems.fold<double>(0.0, (s, ex) => s + ex.price);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // date header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(date, style: Theme.of(context).textTheme.bodySmall),
                                Text('₹ ${dayTotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // transactions for the day (plain background)
                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: dayItems.length,
                            separatorBuilder: (_, __) => const Divider(height: 0.1),
                            itemBuilder: (context, i) {
                              final e = dayItems[i];
                              final typeName = (e.expenseType is String) ? e.expenseType : (e.expenseType?.name ?? '');
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                title: Text(e.name, style: Theme.of(context).textTheme.bodyLarge),
                                subtitle: Text('$typeName • ${e.date.toLocal().hour.toString().padLeft(2,'0')}:${e.date.toLocal().minute.toString().padLeft(2,'0')} ${e.date.hour >= 12 ? 'PM' : 'AM'}'),
                                trailing: Text('${e.price.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge),
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