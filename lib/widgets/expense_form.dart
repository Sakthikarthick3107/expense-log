import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class ExpenseForm extends StatefulWidget {


  final DateTime expenseDate;
  final Expense2? expense;

  const ExpenseForm({
    super.key,
    required this.expenseDate,
    this.expense
  });

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  int selectedExpenseTypeId = 0;

  late ExpenseService _expenseService;
  late SettingsService _settingsService;
  late UiService  _uiService;

  @override
  void initState(){
    super.initState();
    _expenseService = Provider.of<ExpenseService>(context , listen: false);
    _settingsService = Provider.of<SettingsService>(context,listen: false);
    _uiService = Provider.of<UiService>(context,listen: false);
    _nameController.addListener((){
      setState(() {

      });
    });
    _priceController.addListener((){
      setState(() {

      });
    });

    if(widget.expense != null){
      _nameController.text = widget.expense!.name;
      _priceController.text = widget.expense!.price.toString();
      selectedExpenseTypeId = widget.expense!.expenseType.id;
    }
    else{
      selectedExpenseTypeId = _expenseService.getExpenseTypes().isNotEmpty ? _expenseService.getExpenseTypes().first.id : -1 ;
    }
  }

  @override
  void dispose(){
    super.dispose();
    _nameController.dispose();
    _priceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(

      title: Text(widget.expense != null ? 'Edit ${widget.expense?.name}' : 'New Expense'),
      content: Form(
        key: _formKey,
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Price is mandatory';
                }
                else if(double.tryParse(value)! <= 0){
                  return 'Price must be greater than zero';
                }
                return null;
              },
            ),
            selectedExpenseTypeId == -1 ?
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10,horizontal: 4),
                  alignment: Alignment.center,
                  child:const Text(
                    'Create a type from expense type screen'
                  ),
                )
                :
            DropdownButtonFormField<int>(
              value: selectedExpenseTypeId,
              items: _expenseService.getExpenseTypes().map((expType) {
                return DropdownMenuItem<int>(
                  value: expType.id,
                  child: Text(expType.name),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  selectedExpenseTypeId = newValue!;
                });
              },
              decoration: const InputDecoration(labelText: "Expense Type"),
            ),
          ],
        ),
      ),
      actions: [
        if(widget.expense != null &&
            ( widget.expense?.name == _nameController.text &&
                widget.expense?.price ==  double.tryParse(_priceController.text) &&
                widget.expense?.expenseType.id == selectedExpenseTypeId
            ) )
          Column(
            // mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Created - ${_uiService.displayDay(widget.expense!.created)}'),
              if(widget.expense?.updated != null)
              Text('Updated - ${_uiService.displayDay(widget.expense!.updated!)}')
            ],
          ),
        if(
            ( widget.expense?.name != _nameController.text ||
                widget.expense?.price !=  double.tryParse(_priceController.text) ||
                widget.expense?.expenseType.id != selectedExpenseTypeId
            ) )
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if(
            ( widget.expense?.name != _nameController.text ||
                widget.expense?.price !=  double.tryParse(_priceController.text) ||
                widget.expense?.expenseType.id != selectedExpenseTypeId
            ) )
        ElevatedButton(

          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final name = _nameController.text;
              final price = double.parse(_priceController.text);

              final selectedExpenseType = _expenseService.getExpenseTypes().firstWhere(
                    (expType) => expType.id == selectedExpenseTypeId,
              );


              final exp = Expense2(
                id: widget.expense?.id ?? await _settingsService.getBoxKey('expenseId'),
                name: name,
                price: price,
                date: widget.expenseDate,
                created: widget.expense?.created ?? DateTime.now(),
                expenseType: selectedExpenseType,
                updated: widget.expense != null ? DateTime.now() : null,
              );


              int result = _expenseService.createExpense(exp);
              if(result == 1){
                Navigator.pop(context,true);
                MessageWidget.showSnackBar(
                    context: context,
                    message: ' ${widget.expense ==null ? 'Created' : 'Edited' } expense ${exp.name}',
                    status: result);
              }

            }
          },
          child: Text(widget.expense != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
