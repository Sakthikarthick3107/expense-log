import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_log/models/ParsedSmsTxn.dart';
import 'package:expense_log/models/account.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/services/sms_sync_service.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/accounts_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/widgets/message_widget.dart';

class SmsReviewPage extends StatefulWidget {
  final Account account;
  const SmsReviewPage({Key? key, required this.account}) : super(key: key);

  @override
  State<SmsReviewPage> createState() => _SmsReviewPageState();
}

class _SmsReviewPageState extends State<SmsReviewPage> {
  late SmsSyncService _smsSync;
  late ExpenseService _expenseService;
  late AccountsService _accountsService;
  late SettingsService _settings_service;

  List<ParsedSmsTxn> _parsed = [];
  Map<int, dynamic> _selectedTypeForRow =
      {}; // map index -> expenseTypeId (int or String)
  final Set<int> _selectedIndexes = {}; // indexes selected for batch operations
  bool _selectAll = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _smsSync = Provider.of<SmsSyncService>(context, listen: false);
    _expenseService = Provider.of<ExpenseService>(context, listen: false);
    _accountsService = Provider.of<AccountsService>(context, listen: false);
    _settings_service = Provider.of<SettingsService>(context, listen: false);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final parsed = await _smsSync.sync(widget.account);
    setState(() {
      _parsed = parsed;
      _loading = false;
    });
  }

  Future<void> _createExpenseFromRow(int idx) async {
    final txn = _parsed[idx];
    final typeId = _selectedTypeForRow[idx];
    if (typeId == null) {
      MessageWidget.showToast(
          context: context, message: 'Select type first', status: 0);
      return;
    }

    final key = await _settings_service.getBoxKey('expenseId');
    final newId = key is int
        ? key
        : int.tryParse(key.toString()) ?? DateTime.now().millisecondsSinceEpoch;

    final ExpenseType type = _expenseService
        .getExpenseTypes()
        .firstWhere((t) => t.id.toString() == typeId.toString());

    final exp = Expense2(
      id: newId,
      name: txn.description.length > 40
          ? txn.description.substring(0, 40)
          : txn.description,
      price: txn.amount,
      expenseType: type,
      date: txn.date,
      created: DateTime.now(),
      updated: DateTime.now(),
      accountId: widget.account.id is int
          ? widget.account.id as int
          : int.tryParse(widget.account.id.toString()),
    );

    // If txn is credit we create negative amount? (keep positive but allow user to decide)
    // Here we only auto-create for debits. If credit, show message and skip by default.
    if (!txn.isDebit) {
      MessageWidget.showToast(
          context: context,
          message: 'Detected credit - please review before creating',
          status: 0);
      return;
    }

    final res = await _expenseService.createExpense(exp);
    if (res == 1) {
      MessageWidget.showToast(
          context: context, message: 'Expense created', status: 1);

      // Do NOT update account.lastSmsSyncedAt here.
      // lastSmsSyncedAt will be updated after batch creation in _createSelected.
      setState(() {
        _parsed.removeAt(idx);
      });
    } else {
      MessageWidget.showToast(
          context: context, message: 'Failed creating expense', status: 0);
    }
  }

  Future<void> _createSelected() async {
    if (_selectedIndexes.isEmpty) {
      MessageWidget.showToast(
          context: context, message: 'No rows selected', status: 0);
      return;
    }
    // ensure every selected row has a mapped type
    for (final idx in _selectedIndexes) {
      if (_selectedTypeForRow[idx] == null) {
        MessageWidget.showToast(
            context: context,
            message: 'Map type for all selected rows',
            status: 0);
        return;
      }
    }

    setState(() => _loading = true);
    int created = 0;
    DateTime? latestCreatedAt;
    final idxs = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
    for (final idx in idxs) {
      try {
        final txn = _parsed[idx];
        final typeId = _selectedTypeForRow[idx];
        final key = await _settings_service.getBoxKey('expenseId');
        final newId = key is int
            ? key
            : int.tryParse(key.toString()) ??
                DateTime.now().millisecondsSinceEpoch;
        final ExpenseType type = _expenseService
            .getExpenseTypes()
            .firstWhere((t) => t.id.toString() == typeId.toString());

        final price = txn.isDebit ? txn.amount : -txn.amount;

        final exp = Expense2(
          id: newId,
          name: txn.description.length > 40
              ? txn.description.substring(0, 40)
              : txn.description,
          price: price,
          expenseType: type,
          date: txn.date,
          created: DateTime.now(),
          updated: DateTime.now(),
          accountId: widget.account.id is int
              ? widget.account.id as int
              : int.tryParse(widget.account.id.toString()),
        );

        final res = await _expenseService.createExpense(exp);
        if (res == 1) {
          created++;
          latestCreatedAt =
              (latestCreatedAt == null || txn.date.isAfter(latestCreatedAt))
                  ? txn.date
                  : latestCreatedAt;
          setState(() {
            _parsed.removeAt(idx);
          });
        }
      } catch (_) {}
    }

    if (created > 0 && latestCreatedAt != null) {
      try {
        final now = latestCreatedAt;
        final updatedAccount = (widget.account as dynamic).copyWith != null
            ? (widget.account as dynamic).copyWith(lastSmsSyncedAt: now)
            : (widget.account as dynamic)
          ..lastSmsSyncedAt = now;
        await _accountsService.update(updatedAccount);
      } catch (_) {}
    }

    _selectedIndexes.clear();
    _selectAll = false;
    setState(() => _loading = false);

    MessageWidget.showToast(
        context: context,
        message: 'Created $created expenses',
        status: created > 0 ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    final types = _expenseService.getExpenseTypes();
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Review'),
        actions: [
          IconButton(
            icon: Icon(
                _selectAll ? Icons.check_box : Icons.check_box_outline_blank),
            onPressed: () {
              setState(() {
                _selectAll = !_selectAll;
                _selectedIndexes.clear();
                if (_selectAll) {
                  for (int i = 0; i < _parsed.length; i++)
                    _selectedIndexes.add(i);
                }
              });
            },
            tooltip: 'Select all',
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _parsed.isEmpty
              ? const Center(child: Text('No new transactions'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: _parsed.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (ctx, i) {
                          final p = _parsed[i];
                          final selected = _selectedIndexes.contains(i);
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (selected)
                                  _selectedIndexes.remove(i);
                                else
                                  _selectedIndexes.add(i);
                                _selectAll = _selectedIndexes.length == _parsed.length;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // selection checkbox
                                  Checkbox(
                                    value: selected,
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true)
                                          _selectedIndexes.add(i);
                                        else
                                          _selectedIndexes.remove(i);
                                        _selectAll = _selectedIndexes.length == _parsed.length;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  // message + mapping (takes remaining width)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // message description (full width)
                                        Text(
                                          p.description,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        // small meta row (date / debit/credit / amount)
                                        Text(
                                          '${p.date.toLocal()} • ${p.isDebit ? 'Debit' : 'Credit'} • ${p.amount.toStringAsFixed(2)}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 8),
                                        // type mapping below description (full width dropdown)
                                        DropdownButtonFormField<dynamic>(
                                          value: _selectedTypeForRow[i],
                                          style: const TextStyle(fontSize: 12),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                            border: OutlineInputBorder(),
                                            labelText: 'Expense Type',
                                          ),
                                          items: types
                                              .map((t) => DropdownMenuItem<dynamic>(
                                                    value: t.id,
                                                    child: Text(t.name, style: TextStyle(fontSize: 12)),
                                                  ))
                                              .toList(),
                                          onChanged: (v) => setState(() => _selectedTypeForRow[i] = v),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // persistent bottom bar with Cancel + Create (fixed height)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      height: 72,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1))],
                      ),
                      child: Row(
                        children: [
                          Text('${_parsed.length} found', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(width: 12),
                          Expanded(child: Text('${_selectedIndexes.length} selected', style: Theme.of(context).textTheme.bodyMedium)),
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
                            onPressed: _selectedIndexes.isNotEmpty ? _createSelected : null,
                            child: const Text('Create'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
