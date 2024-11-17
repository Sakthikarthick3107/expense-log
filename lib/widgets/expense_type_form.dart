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
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(

      shape:const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Text( widget.type == null ? 'New Type':'Edit Type'),
      content: Form(
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
                return null;
              },
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),

            ),
          ],
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
            final expType = ExpenseType(
                id: widget.type?.id ?? await _settingsService.getBoxKey('expenseTypeId'),
                name: name,
                description: description
            );
            int result = _expenseService.createExpenseType(expType);
            if(result == 1){
              Navigator.pop(context,true);
              MessageWidget.showSnackBar(
                  context: context,
                  message:'${widget.type == null ? 'Created' : 'Edited'} type - ${expType.name}',
                  status: result);
            }
            else{
              Navigator.pop(context,false);
              MessageWidget.showSnackBar(
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
