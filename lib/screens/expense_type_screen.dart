import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/widgets/expense_type_form.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

class ExpenseTypeScreen extends StatefulWidget {
  const ExpenseTypeScreen({super.key});

  @override
  State<ExpenseTypeScreen> createState() => _ExpenseTypeScreenState();
}

class _ExpenseTypeScreenState extends State<ExpenseTypeScreen> {
  late ExpenseService _expenseService;
  late UiService _uiService;

  @override
  void initState(){
    super.initState();
    _expenseService = Provider.of<ExpenseService>(context,listen: false);
    _uiService = Provider.of<UiService>(context,listen: false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Container(

              padding:const EdgeInsets.all(14),
                margin:const EdgeInsets.only(bottom: 20,),


                child: const Text(
                      'Type',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold
                      ),
                    ),
              ),


          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<ExpenseType>('expenseTypeBox').listenable(),
              builder: (context, Box<dynamic> box, _) {
                final expTypes = _expenseService.getExpenseTypes();
                if (expTypes.isEmpty) {
                  return const  Center(
                    child: Text('No types'),
                  );
                }
                return ListView(
                  children: expTypes.map((expType) {
                    return ListTile(
                      onTap: (){
                        showDialog(context: context,
                            builder: (context) => ExpenseTypeForm(
                              type: expType,
                            )
                        );
                      },
                      title: Text(expType.name),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(context: context,
              builder: (context) =>const ExpenseTypeForm()
          );
        },
        child: const Icon(
          Icons.add,
          size: 30,
        ),
      ),
    );
  }

}
