

import 'package:expense_log/models/expense.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:hive/hive.dart';

Future<void> expense_data_type_migration2() async{

  final expenseBox = Hive.box<Expense>('expenseBox');
  final expenseTypeBox =  Hive.box<ExpenseType>('expenseTypeBox');
  final expense2Box = Hive.box<Expense2>('expense2Box');

  final expenses = expenseBox.values.toList();
  final expenseTypeMap = Map.fromIterable(expenseTypeBox.values, key: (e) => e.name);

  for(var expense in expenses){

      ExpenseType? getByExpenseTypeName = expenseTypeMap[expense.expenseType];
      if (getByExpenseTypeName != null) {
        Expense2 newExpense = Expense2(
            id: expense.id,
            name: expense.name,
            price: expense.price,
            expenseType: getByExpenseTypeName,
            date: expense.date,
            created: expense.created,
            updated: expense.updated
        );
          expense2Box.put(newExpense.id,newExpense);
      }

  }
  if(expenseBox.isNotEmpty){
    await expenseBox.deleteFromDisk();
  }
}