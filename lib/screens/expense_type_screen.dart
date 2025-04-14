import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/widgets/expense_type_form.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class ExpenseTypeScreen extends StatefulWidget {
  const ExpenseTypeScreen({super.key});

  @override
  State<ExpenseTypeScreen> createState() => _ExpenseTypeScreenState();
}

class _ExpenseTypeScreenState extends State<ExpenseTypeScreen> {
  late ExpenseService _expenseService;
  late UiService _uiService;
  late SettingsService _settingsService;

  @override
  void initState(){
    super.initState();
    _expenseService = Provider.of<ExpenseService>(context,listen: false);
    _uiService = Provider.of<UiService>(context,listen: false);
    _settingsService = Provider.of<SettingsService>(context,listen: false);
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SettingsService>(
        builder: (context,settingsService , child){
         return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: Hive.box<ExpenseType>('expenseTypeBox').listenable(),
                  builder: (context, Box<dynamic> box, _) {
                    final expTypes = _expenseService.getExpenseTypes();
                    if (expTypes.isEmpty) {
                      return  Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/add-note.json',
                            width: 200,
                            height: 200,
                          ),
                          const Text(
                            'Tap + icon to create a relevant expense type for your expenses',
                            style: TextStyle(
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    }
                    return Container(
                      padding: EdgeInsets.all(10),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: Platform.isWindows ? 8 : 2,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 4,
                            childAspectRatio: 3

                        ),
                        itemCount: expTypes.length,
                        itemBuilder: (context, index) {
                          final expType = expTypes[index];
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => ExpenseTypeForm(
                                  type: expType,
                                ),
                              );
                            },
                            child: Card(
                              elevation: settingsService.getElevation() ? 8: 0,
                              color: settingsService.getElevation() ? Theme.of(context).cardColor : Colors.transparent,

                              child: ListTile(
                                title: Text(
                                    expType.name,
                                    style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                  ),
                                subtitle: (expType.limit != null && (expType.limitBy?.isNotEmpty ?? false))
                                    ? Text(
                                  '${expType.limitBy!} ( ${_expenseService.getTypeLimitUsage(expType)} / ${expType.limit} )',
                                  style:  TextStyle(
                                      fontSize: 10,
                                    color: (expType.limit != null &&
                                        _expenseService.getTypeLimitUsage(expType) > expType.limit!)
                                        ? Colors.red
                                        : Theme.of(context).textTheme.displayMedium?.color,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ) : null,


                              ),
                            ),
                          );
                        },
                      ),
                    );

                  },
                ),
              ),
            ],
          );
        }

      ),
      floatingActionButton: Container(
        margin: EdgeInsets.symmetric(vertical: 50,horizontal: 30),
        child: FloatingActionButton(
          onPressed: () {
            showDialog(context: context,
                builder: (context) =>const ExpenseTypeForm()
            );
          },
          tooltip: 'Create new type',
          child: const Icon(
            Icons.add,
            size: 30,
          ),
        ),
      ),
    );
  }

}
