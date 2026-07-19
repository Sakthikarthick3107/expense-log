import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/group.dart';
import 'package:expense_log/services/accounts_service.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:expense_log/widgets/voice_input.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GroupExpenseForm extends StatefulWidget {
  final Group group;
  final DateTime expenseDate;
  final Expense2? expense;
  final VoiceParseResult? prefill;

  const GroupExpenseForm({
    super.key,
    required this.group,
    required this.expenseDate,
    this.expense,
    this.prefill,
  });

  @override
  State<GroupExpenseForm> createState() => _GroupExpenseFormState();
}

class _GroupExpenseFormState extends State<GroupExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  int selectedExpenseTypeId = 0;
  int? _selectedAccountId;
  String _selectedUser = 'Me';
  bool _isCredit = false;

  late ExpenseService _expenseService;
  late SettingsService _settingsService;

  @override
  void initState() {
    super.initState();
    _expenseService = Provider.of<ExpenseService>(context, listen: false);
    _settingsService = Provider.of<SettingsService>(context, listen: false);

    if (widget.expense != null) {
      _nameController.text = widget.expense!.name;
      _priceController.text = widget.expense!.price.abs().toString();
      _descriptionController.text =
          widget.expense!.description ?? '';
      selectedExpenseTypeId = widget.expense!.expenseType.id;
      _selectedAccountId = widget.expense!.accountId;
      _selectedUser = widget.expense!.mappedUserName ?? 'Me';
      _isCredit = widget.expense!.price < 0;
    } else {
      final types = _expenseService.getExpenseTypes();
      selectedExpenseTypeId = types.isNotEmpty ? types.first.id : -1;
    }
    if (widget.prefill != null) _applyVoiceResult(widget.prefill!);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyVoiceResult(VoiceParseResult result) {
    if (result.amount != null) _priceController.text = result.amount!;
    if (result.typeName != null) {
      final match = _expenseService.getExpenseTypes().where(
          (t) => t.name.toLowerCase() == result.typeName!.toLowerCase());
      if (match.isNotEmpty) selectedExpenseTypeId = match.first.id;
    }
    if (result.isCredit != null) _isCredit = result.isCredit!;
    if (result.accountName != null) {
      final accounts = Provider.of<AccountsService>(context, listen: false).all;
      final match = accounts.where(
          (a) => a.name.toLowerCase() == result.accountName!.toLowerCase());
      if (match.isNotEmpty) _selectedAccountId = match.first.id;
    }
    if (result.groupUserName != null) {
      _selectedUser = result.groupUserName!;
    }
    if (_nameController.text.isEmpty || result.fullText.isNotEmpty) {
      _nameController.text = result.fullText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = Provider.of<AccountsService>(context).all;
    return AlertDialog(
      title: Text(widget.expense != null
          ? 'Edit ${widget.expense?.name}'
          : 'New Group Expense'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                isDense: true,
                value: _selectedUser,
                items: widget.group.members.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(m),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedUser = v!),
                decoration: const InputDecoration(
                  labelText: 'Mapped User',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Enter expense',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Expense is mandatory' : null,
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Amount is mandatory' : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 44,
                    child: DropdownButton<String>(
                      value: _isCredit ? 'Credit' : 'Debit',
                      onChanged: (v) =>
                          setState(() => _isCredit = v == 'Credit'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Debit', child: Text('Debit')),
                        DropdownMenuItem(
                            value: 'Credit', child: Text('Credit')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (selectedExpenseTypeId == -1)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  alignment: Alignment.center,
                  child: const Text('Create a type from expense type screen'),
                )
              else ...[
                DropdownButtonFormField<int>(
                  isDense: true,
                  value: selectedExpenseTypeId,
                  items: _expenseService.getExpenseTypes().map((t) {
                    return DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedExpenseTypeId = v!),
                  decoration: const InputDecoration(
                    labelText: 'Expense Type',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  isDense: true,
                  value: _selectedAccountId,
                  items: accounts
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.name} (${a.code})',
                                style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                  decoration: const InputDecoration(
                    labelText: 'Payment Account',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (v) => v == null ? 'Select account' : null,
                ),
              ],
              const SizedBox(height: 4),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                keyboardType: TextInputType.multiline,
                maxLines: 2,
                minLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final rawPrice = double.parse(_priceController.text);
              final price = _isCredit ? -rawPrice : rawPrice;
              final type = _expenseService.getExpenseTypes().firstWhere(
                    (t) => t.id == selectedExpenseTypeId,
                  );
              final exp = Expense2(
                id: widget.expense?.id ??
                    await _settingsService.getBoxKey('expenseId'),
                name: _nameController.text,
                price: price,
                date: widget.expenseDate,
                created: widget.expense?.created ?? DateTime.now(),
                expenseType: type,
                accountId: _selectedAccountId,
                updated: widget.expense != null ? DateTime.now() : null,
                description: _descriptionController.text,
                groupId: widget.group.id,
                mappedUserName: _selectedUser,
              );
              final result = _expenseService.createExpense(exp);
              if (result == 1) {
                Navigator.pop(context, true);
                MessageWidget.showToast(
                  context: context,
                  message:
                      '${widget.expense == null ? 'Created' : 'Edited'} expense ${exp.name}',
                  status: 1,
                );
              } else {
                MessageWidget.showToast(
                  context: context,
                  message: 'Error while creating expense',
                  status: 0,
                );
              }
            }
          },
          child: Text(widget.expense != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
