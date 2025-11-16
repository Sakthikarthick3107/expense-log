import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/widgets/info_dialog.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:expense_log/widgets/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_log/services/accounts_service.dart';
import 'package:expense_log/models/account.dart';

class ExpenseForm extends StatefulWidget {
  final DateTime expenseDate;
  final Expense2? expense;
  final bool? isFromCollection;

  const ExpenseForm(
      {super.key,
      required this.expenseDate,
      this.expense,
      this.isFromCollection});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isReturnable = false;
  int selectedExpenseTypeId = 0;
  int? _selectedAccountId;

  late ExpenseService _expenseService;
  late SettingsService _settingsService;
  late UiService _uiService;

  @override
  void initState() {
    super.initState();
    _expenseService = Provider.of<ExpenseService>(context, listen: false);
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _uiService = Provider.of<UiService>(context, listen: false);
    _nameController.addListener(() {
      setState(() {});
    });
    _priceController.addListener(() {
      setState(() {});
    });

    if (widget.expense != null) {
      _nameController.text = widget.expense!.name;
      _priceController.text = widget.expense!.price.toString();
      selectedExpenseTypeId = widget.expense!.expenseType.id;
      // try to read accountId from provided expense (robust to int or String)
      final rawAccount = (widget.expense as dynamic).accountId;
      if (rawAccount is int) {
        _selectedAccountId = rawAccount;
      } else if (rawAccount is String) {
        _selectedAccountId = int.tryParse(rawAccount);
      } else {
        _selectedAccountId = null;
      }
      // _isReturnable = widget.expense!.isReturnable ?? false;
    } else {
      selectedExpenseTypeId = _expenseService.getExpenseTypes().isNotEmpty
          ? _expenseService.getExpenseTypes().first.id
          : -1;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    _priceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = Provider.of<AccountsService>(context).all;
    return AlertDialog(
      title: Text(widget.expense != null
          ? 'Edit ${widget.expense?.name}'
          : 'New Expense'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Enter expense'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Expense is mandatory';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Price is mandatory';
                  }
                  return null;
                },
              ),
              selectedExpenseTypeId == -1
                  ? Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      alignment: Alignment.center,
                      child:
                          const Text('Create a type from expense type screen'),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          DropdownButtonFormField<int>(
                            value: selectedExpenseTypeId,
                            items: _expenseService
                                .getExpenseTypes()
                                .map((expType) {
                              return DropdownMenuItem<int>(
                                value: expType.id,
                                child: Text(expType.name,
                                    style: TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              setState(() {
                                selectedExpenseTypeId = newValue!;
                                // Auto-map account from selected ExpenseType only if user hasn't chosen account
                                try {
                                  final selType = _expenseService
                                      .getExpenseTypes()
                                      .firstWhere(
                                          (t) => t.id == selectedExpenseTypeId);
                                  final defAcc =
                                      (selType as dynamic).defaultAccountId;
                                  if ((_selectedAccountId == null) &&
                                      defAcc != null) {
                                    if (defAcc is int) {
                                      _selectedAccountId = defAcc;
                                    } else if (defAcc is String) {
                                      _selectedAccountId = int.tryParse(defAcc);
                                    }
                                  }
                                } catch (_) {}
                              });
                            },
                            decoration: const InputDecoration(
                                labelText: "Expense Type"),
                          ),
                          const SizedBox(height: 8),
                          // Account dropdown (required)
                          DropdownButtonFormField<int>(
                            value: _selectedAccountId,
                            items: accounts
                                .map((Account a) {
                                  // account.id may be String in some code; attempt int parse if needed
                                  int? aid;
                                  try {
                                    if (a.id is int) {
                                      aid = a.id as int;
                                    } else {
                                      aid = int.tryParse(a.id.toString());
                                    }
                                  } catch (_) {
                                    aid = null;
                                  }
                                  return DropdownMenuItem<int>(
                                    value: aid,
                                    child: Text(
                                        '${a.name} ${a.code != null ? '(${a.code})' : ''}',
                                        style: TextStyle(fontSize: 12),
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                      ),
                                  );
                                  ;
                                })
                                .where((item) => item.value != null)
                                .toList(),
                            onChanged: (int? v) =>
                                setState(() => _selectedAccountId = v),
                            decoration: const InputDecoration(
                                labelText: 'Payment Account'),
                            validator: (v) {
                              if (v == null) return 'Select account';
                              return null;
                            },
                          ),
                        ]),
              // if (widget.isFromCollection != true)
              // CheckboxListTile(
              //     title: Text('Refundable?'),
              //     value: _isReturnable,
              //     onChanged: (value){
              //       setState(() {
              //         _isReturnable = value ?? false;
              //       });
              //     })
            ],
          ),
        ),
      ),
      actions: [
        if (widget.expense != null &&
            (widget.expense?.name == _nameController.text &&
                widget.expense?.price ==
                    double.tryParse(_priceController.text) &&
                widget.expense?.expenseType.id == selectedExpenseTypeId
            // && widget.expense?.isReturnable == _isReturnable
            ))
          Column(
            // mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Created - ${_uiService.displayDay(widget.expense!.created)}'),
              if (widget.expense?.updated != null)
                Text(
                    'Updated - ${_uiService.displayDay(widget.expense!.updated!)}')
            ],
          ),
        if ((widget.expense?.name != _nameController.text ||
                widget.expense?.price !=
                    double.tryParse(_priceController.text) ||
                widget.expense?.expenseType.id != selectedExpenseTypeId ||
                widget.expense?.accountId != _selectedAccountId
            // || widget.expense?.isReturnable == _isReturnable
            ))
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        if ((widget.expense?.name != _nameController.text ||
                widget.expense?.price !=
                    double.tryParse(_priceController.text) ||
                widget.expense?.expenseType.id != selectedExpenseTypeId ||
                widget.expense?.accountId != _selectedAccountId
            // || widget.expense?.isReturnable == _isReturnable
            ))
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final name = _nameController.text;
                final price = double.parse(_priceController.text);

                final selectedExpenseType =
                    _expenseService.getExpenseTypes().firstWhere(
                          (expType) => expType.id == selectedExpenseTypeId,
                        );

                final exp = Expense2(
                  id: widget.expense?.id ??
                      await _settingsService.getBoxKey('expenseId'),
                  name: name,
                  price: price,
                  date: widget.expenseDate,
                  created: widget.expense?.created ?? DateTime.now(),
                  expenseType: selectedExpenseType,
                  accountId: _selectedAccountId, // nullable int
                  updated: widget.expense != null ? DateTime.now() : null,
                  // isReturnable: widget.expense?.isReturnable ?? _isReturnable
                );

                if (widget.isFromCollection == true) {
                  exp.id = -1;
                  Navigator.pop(context, exp);
                } else {
                  var getExceedList = _expenseService.exceededExpenses([exp]);
                  int result = _expenseService.createExpense(exp);

                  if (result == 1) {
                    Navigator.pop(context, true);
                    if (getExceedList != null) {
                      InfoDialog.showInfo(
                          title: 'Limit Info',
                          context: context,
                          content: [Text(getExceedList.join('\n'))]);
                    }
                    MessageWidget.showToast(
                        context: context,
                        message:
                            ' ${widget.expense == null ? 'Created' : 'Edited'} expense ${exp.name}',
                        status: 1);
                  } else {
                    MessageWidget.showToast(
                        context: context,
                        message: 'Error while creating expense',
                        status: 0);
                  }
                }
              }
            },
            child: Text(widget.expense != null ? 'Update' : 'Create'),
          ),
      ],
    );
  }
}
