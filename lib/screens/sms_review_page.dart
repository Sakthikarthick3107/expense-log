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

  String _fmtDateTimeShort(DateTime d) {
    final dt = d.toLocal();
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final date = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
    return '$date $hour:$min';
  }

  Future<void> _createExpenseFromRow(int idx) async {
    final txn = _parsed[idx];
    final typeId = _selectedTypeForRow[idx];
    if (typeId == null) {
      MessageWidget.showToast(context: context, message: 'Select type first', status: 0);
      return;
    }

    final key = await _settings_service.getBoxKey('expenseId');
    final newId = key is int ? key : int.tryParse(key.toString()) ?? DateTime.now().millisecondsSinceEpoch;

    final ExpenseType type = _expenseService
        .getExpenseTypes()
        .firstWhere((t) => t.id.toString() == typeId.toString());

    final baseName = txn.description.length > 40 ? txn.description.substring(0, 40) : txn.description;
    final remark = ' (synced via ${widget.account.name} SMS at ${_fmtDateTimeShort(txn.date)})';
    final exp = Expense2(
      id: newId,
      name: baseName + remark,
      price: txn.amount,
      expenseType: type,
      date: txn.date,
      created: DateTime.now(),
      updated: DateTime.now(),
      accountId: widget.account.id is int ? widget.account.id as int : int.tryParse(widget.account.id.toString()),
    );

    // credit => negative amount (if your logic requires)
    if (!txn.isDebit) {
      MessageWidget.showToast(context: context, message: 'Detected credit - please review before creating', status: 0);
      return;
    }

    final res = await _expenseService.createExpense(exp);  
    if (res == 1) {
      MessageWidget.showToast(context: context, message: 'Expense created', status: 1);

      // Do NOT update account.lastSmsSyncedAt here.
      setState(() {
        _parsed.removeAt(idx);
      });
    } else {
      MessageWidget.showToast(context: context, message: 'Failed creating expense', status: 0);
    }
  }

  Future<void> _createSelected() async {
    if (_selectedIndexes.isEmpty) {
      MessageWidget.showToast(context: context, message: 'No rows selected', status: 0);
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
        final newId = key is int ? key : int.tryParse(key.toString()) ?? DateTime.now().millisecondsSinceEpoch;
        final ExpenseType type = _expenseService.getExpenseTypes().firstWhere((t) => t.id.toString() == typeId.toString());

        // credit => negative amount
        final price = txn.isDebit ? txn.amount : -txn.amount;

        final baseName = txn.description.length > 40 ? txn.description.substring(0, 40) : txn.description;
        final remark = ' (synced via ${widget.account.name} SMS at ${_fmtDateTimeShort(txn.date)})';
        final exp = Expense2(
          id: newId,
          name: baseName,
          price: price,
          expenseType: type,
          date: txn.date,
          created: DateTime.now(),
          updated: DateTime.now(),
          description: remark,
          accountId: widget.account.id is int ? widget.account.id as int : int.tryParse(widget.account.id.toString()),
        );

        final res = await _expenseService.createExpense(exp);
        if (res == 1) {
          created++;
          latestCreatedAt = (latestCreatedAt == null || txn.date.isAfter(latestCreatedAt)) ? txn.date : latestCreatedAt;
          // remove parsed row
          setState(() { _parsed.removeAt(idx); });
        }
      } catch (_) {
        // skip row on error
      }
    }

    if (created > 0 && latestCreatedAt != null) {
      try {
        // create a new Account instance with lastSmsSyncedAt updated.
        final acct = widget.account;
        final updatedAccount = Account(
          id: acct.id,
          name: acct.name,
          code: acct.code,
          description: acct.description,
          createdAt: acct.createdAt,
          updatedAt: DateTime.now(),
          // preserve other fields if present (smsKeyword, lastSmsSyncedAt etc.)
          smsKeyword: acct.smsKeyword,
          lastSmsSyncedAt: latestCreatedAt,
        );
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
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                            border: const OutlineInputBorder(),
                                            labelText: 'Expense Type',
                                          ),
                                          // Use theme-aware text color so it shows correctly in light/dark mode
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                          dropdownColor: Theme.of(context).cardColor,
                                          items: types
                                              .map((t) => DropdownMenuItem<dynamic>(
                                                    value: t.id,
                                                    child: Text(
                                                      t.name,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                                      ),
                                                    ),
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
