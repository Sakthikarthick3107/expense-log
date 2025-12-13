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
  Map<int, dynamic> _selectedTypeForRow = {}; // map index -> expenseTypeId (int or String)
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
      MessageWidget.showToast(context: context, message: 'Select type first', status: 0);
      return;
    }

    final key = await _settings_service.getBoxKey('expenseId');
    final newId = key is int ? key : int.tryParse(key.toString()) ?? DateTime.now().millisecondsSinceEpoch;

    final ExpenseType type = _expenseService
        .getExpenseTypes()
        .firstWhere((t) => t.id.toString() == typeId.toString());

    final exp = Expense2(
      id: newId,
      name: txn.description.length > 40 ? txn.description.substring(0, 40) : txn.description,
      price: txn.amount,
      expenseType: type,
      date: txn.date,
      created: DateTime.now(),
      updated: DateTime.now(),
      accountId: widget.account.id is int ? widget.account.id as int : int.tryParse(widget.account.id.toString()),
    );

    // If txn is credit we create negative amount? (keep positive but allow user to decide)
    // Here we only auto-create for debits. If credit, show message and skip by default.
    if (!txn.isDebit) {
      MessageWidget.showToast(context: context, message: 'Detected credit - please review before creating', status: 0);
      return;
    }

    final res = await _expenseService.createExpense(exp);
    if (res == 1) {
      MessageWidget.showToast(context: context, message: 'Expense created', status: 1);
      // Optionally mark sms synced time on account elsewhere
      setState(() {
        _parsed.removeAt(idx);
      });
    } else {
      MessageWidget.showToast(context: context, message: 'Failed creating expense', status: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = _expenseService.getExpenseTypes();
    return Scaffold(
      appBar: AppBar(title: const Text('SMS Review')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _parsed.isEmpty
              ? const Center(child: Text('No new transactions'))
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _parsed.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final p = _parsed[i];
                    return ListTile(
                      title: Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${p.date.toLocal()} • ${p.isDebit ? 'Debit' : 'Credit'} • ${p.amount.toStringAsFixed(2)}'),
                      trailing: SizedBox(
                        width: 220,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: DropdownButton<dynamic>(
                                isDense: true,
                                value: _selectedTypeForRow[i],
                                hint: const Text('Type'),
                                items: types
                                    .map((t) => DropdownMenuItem<dynamic>(value: t.id, child: Text(t.name)))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedTypeForRow[i] = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: p.isDebit ? () => _createExpenseFromRow(i) : null,
                              child: const Text('Create'),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
