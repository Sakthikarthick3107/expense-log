import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class ExpenseTypeForm extends StatefulWidget {
  final ExpenseType? type;

  const ExpenseTypeForm({
    super.key,
    this.type
  });

  @override
  State<ExpenseTypeForm> createState() => _ExpenseTypeFormState();
}

class _ExpenseTypeFormState extends State<ExpenseTypeForm> {

  final _formKey =GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _limitController = TextEditingController();
  String? _selectedLimitBy;
  final List<String> _limitOptions = ['Week', 'Month'];

  late SettingsService _settingsService;
  late ExpenseService _expenseService;

  @override
  void initState(){
    super.initState();
    _settingsService = Provider.of<SettingsService>(context,listen: false);
    _expenseService = Provider.of<ExpenseService>(context,listen: false);
    if(widget.type != null){
      _nameController.text = widget.type!.name;
      _descriptionController.text = widget.type!.description!;
      _limitController.text = widget.type!.limit?.toString() ?? '';
      _selectedLimitBy = widget.type!.limitBy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text( widget.type == null ? 'New Type':'Edit Type'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Type'),
                validator: (value){
                  if(value==null){
                    return 'Type is mandatory';
                  }
                  else if(value.length > 20){
                    return 'Length should not exceed 20 ';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
        
              ),
              TextFormField(
                controller: _limitController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Limit (optional)'),
                onChanged: (_) => setState(() {}), // rebuild to show/hide dropdown
              ),

              if (_limitController.text.trim().isNotEmpty)
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Limit By'),
                  value: _selectedLimitBy,
                  items: _limitOptions.map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedLimitBy = val),
                  validator: (value) {
                    if (_limitController.text.trim().isNotEmpty && (value == null || value.isEmpty)) {
                      return 'Please choose how to apply the limit';
                    }
                    return null;
                  },
                ),
            ],
          ),
        
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(onPressed: ()async{
          if(_formKey.currentState?.validate() ?? false){
            final name = _nameController.text;
            final description = _descriptionController.text ?? '';
            final limit = _limitController.text.isEmpty
                ? null
                : double.tryParse(_limitController.text);
            final limitBy = (_selectedLimitBy?.isEmpty ?? true) || limit == null ? null : _selectedLimitBy;

            final expType = ExpenseType(
                id: widget.type?.id ?? await _settingsService.getBoxKey('expenseTypeId'),
                name: name,
                description: description,
                limit: limit,
                limitBy: limitBy,
            );
            int result = _expenseService.createExpenseType(expType);
            if(result == 1){
              Navigator.pop(context,true);
              MessageWidget.showToast(
                  context: context,
                  message:'${widget.type == null ? 'Created' : 'Edited'} type - ${expType.name}',
                  status: result);
            }
            else if (result == -1) {
              MessageWidget.showToast(
                context: context,
                message: 'Cannot apply limit changes : Already in track for the selected/previous duration ',
              );
            }
            else{
              Navigator.pop(context,false);
              MessageWidget.showToast(
                  context: context,
                  message: 'Type ${expType.name} already exists',
                  status: result);
            }


          }
        }, child: Text(widget.type == null ? 'Create' :'Edit'))
      ],
    );;
  }
}
