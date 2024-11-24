

import 'package:expense_log/models/expense.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/widgets/expense_form.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class DailyExpenseScreen extends StatefulWidget {
  const DailyExpenseScreen({super.key});

  @override
  State<DailyExpenseScreen> createState() => _DailyExpenseScreenState();
}

class _DailyExpenseScreenState extends State<DailyExpenseScreen> {
  late UiService _uiService;
  late ExpenseService _expenseService;
  late SettingsService _settingsService;
  String? expenseType;
  final ValueNotifier<DateTime> _selectedDateNotifier = ValueNotifier<DateTime>(DateTime.now());
  double totalExpense = 0.0;
  Map<int,Expense2> deleteList =  {};

  @override
  void initState(){
      super.initState();
      _uiService = Provider.of<UiService>(context , listen: false);
      _expenseService = Provider.of<ExpenseService>(context,listen: false);
      _settingsService = Provider.of<SettingsService>(context,listen: false);
      totalExpense = _expenseService.selectedDayTotalExpense(_selectedDateNotifier.value);

      _selectedDateNotifier.addListener((){
        setState(() {
          totalExpense = _expenseService.selectedDayTotalExpense(_selectedDateNotifier.value);
          deleteList.clear();
        });
      });
  }

  @override
  void dispose(){
    super.dispose();
    _selectedDateNotifier.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: (){
                      setState(() {
                        _selectedDateNotifier.value =  _selectedDateNotifier.value.subtract(const Duration(days: 1));
                      });


                    },
                    padding:const EdgeInsets.all(20.0),
                    icon:const Icon(Icons.arrow_back_ios)
                ),
                ValueListenableBuilder<DateTime>(
                    valueListenable: _selectedDateNotifier,
                    builder: (context,selectedDate,_){
                        return TextButton(
                            onPressed: ()async{
                              DateTime pickDate =await _uiService.selectDate(context);
                              setState(() {
                                _selectedDateNotifier.value = pickDate;
                              });


                            },
                            child:Text(
                              _uiService.displayDay(_selectedDateNotifier.value),

                              style:const TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700
                              ),
                            )
                        );
                    }),

                IconButton(
                    onPressed: (){
                      setState(() {
                        _selectedDateNotifier.value =  _selectedDateNotifier.value.add(const Duration(days: 1));
                      });

                    },
                    padding:const EdgeInsets.all(20.0),
                    icon:const Icon(Icons.arrow_forward_ios)
                )
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16.0),

              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [

                  ValueListenableBuilder(
                      valueListenable: _selectedDateNotifier,
                      builder: (context,date,_){
                        if(deleteList.isNotEmpty){
                          return TextButton(
                              onPressed: (){
                                _expenseService.deleteExpense(deleteList);
                                  setState(() {

                                    deleteList.clear();
                                    totalExpense = _expenseService.selectedDayTotalExpense(_selectedDateNotifier.value);
                                  });
                              },
                              child: Text(
                                'Delete (${deleteList.length})',
                                style:const TextStyle(
                                    color: Colors.black,
                                    fontSize: 20),
                              )
                          );
                        }
                        else{
                          return Text(
                            "₹${totalExpense.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          );
                        }
                      })
                ],
              ),
            ),
            Expanded(
        child: ValueListenableBuilder(
                  valueListenable: Hive.box<Expense2>('expense2Box').listenable(),
                  builder: (context,Box<Expense2> box,_){
                    final expenseOfTheDate = _expenseService.getExpensesOfTheDay(_selectedDateNotifier.value);
                    if (expenseOfTheDate.isEmpty) {
                      return  Column(

                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/add-note.json',
                              width: 200,
                              height: 200,
                            ),
                            Text(
                                'Tap + icon to create expense for \n ${_uiService.displayDay(_selectedDateNotifier.value)}',
                              style: TextStyle(

                              ),
                                textAlign: TextAlign.center,
                            ),
                          ],

                      );
                    }

                    return ListView(
                        children: expenseOfTheDate.map((expOfDay){
                          return  Container(
                            padding:  const EdgeInsets.symmetric(horizontal: 8.0,vertical: 2.0),
                            decoration:const BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(20))
                            ),
                            child: ListTile(
                                tileColor: deleteList.isNotEmpty && deleteList.containsKey(expOfDay.id) ? Colors.blueGrey : Colors.transparent,
                                onTap: ()async{
                            
                                  if(deleteList.isNotEmpty){
                                    setState(() {
                                      if(deleteList.containsKey(expOfDay.id)){
                                        deleteList.remove(expOfDay.id);
                                      }
                                      else{
                                        deleteList[expOfDay.id] = expOfDay;
                                      }
                                    });
                                  }
                                  else{
                                      final result = await showDialog<bool>(
                                          context: context,
                                          builder: (context) =>ExpenseForm(
                                              expenseDate: _selectedDateNotifier.value,
                                              expense: expOfDay,
                                          )
                                      );
                                      if(result == true){
                                        setState(() {
                                          totalExpense = _expenseService.selectedDayTotalExpense(_selectedDateNotifier.value);
                                        });
                                      }
                                  }
                                },
                                onLongPress: (){
                                  setState(() {
                                    if (!deleteList.containsKey(expOfDay.id)) {
                                      deleteList[expOfDay.id] = expOfDay;
                                    }
                                  });
                                },
                                title: Text(
                                    expOfDay.name,
                                    style:const TextStyle(
                                      fontSize: 24
                                    ),
                                ),
                                subtitle: Text(
                                  expOfDay.expenseType.name
                                ),
                                trailing: Text(
                                    expOfDay.price.toString(),
                                    style:const TextStyle(
                                      fontSize: 22
                                    ),
                                ),
                            ),
                          );
                        }).toList(),
                      );
                  },
                )

            ),


          ],
        ),
      floatingActionButton: Container(
        margin: EdgeInsets.symmetric(vertical: 50,horizontal: 30),
        child: FloatingActionButton(

          onPressed: ()async{
            final result =await showDialog<bool>(
                context: context,
                builder: (context) =>ExpenseForm(
                  expenseDate: _selectedDateNotifier.value
                )
            );
            if(result == true){
              setState(() {
                totalExpense = _expenseService.selectedDayTotalExpense(_selectedDateNotifier.value);
              });

            }

          },
          child: const Icon(
              Icons.add,
            size: 30,
          ),
        ),
      ),
    );
  }
}
