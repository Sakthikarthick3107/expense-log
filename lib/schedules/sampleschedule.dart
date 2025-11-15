// import 'package:expense_log/models/expense2.dart';
// import 'package:expense_log/models/expense_type.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:hive_flutter/adapters.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:workmanager/workmanager.dart';

// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     final appDir = await getApplicationDocumentsDirectory();
//     Hive.init(appDir.path);
//     Hive.registerAdapter(Expense2Adapter());
//     Hive.registerAdapter(ExpenseTypeAdapter());
//     var expenseBox = await Hive.openBox<Expense2>('expense2Box');
//     var settingsBox = await Hive.openBox('settingsBox');
//     if (task == "autoexpense") {
//       var expenseId = settingsBox.get('expenseId', defaultValue: 1) as int;

//       final newExpense = Expense2(
//           id: expenseId,
//           name: 'Schedule entry',
//           price: 90,
//           expenseType: ExpenseType(id: 2, name: 'food'),
//           date: DateTime.now(),
//           created: DateTime.now());

//       await expenseBox.put(expenseId, newExpense);
//       await settingsBox.put('expenseId', ++expenseId);
//       print('Entry - ${newExpense}');
//     }

//     return Future.value(true);
//   });
// }
