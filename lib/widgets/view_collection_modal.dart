import 'package:expense_log/services/collection_service.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:expense_log/widgets/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../models/collection.dart';
import '../services/settings_service.dart';

class ViewCollectionModal extends StatefulWidget {
  List<Collection> collections;
  DateTime expenseDate;
   ViewCollectionModal({super.key , required this.collections , required this.expenseDate});

  @override
  State<ViewCollectionModal> createState() => _ViewCollectionModalState();
}

class _ViewCollectionModalState extends State<ViewCollectionModal> {
  late CollectionService _collectionService;
  late ExpenseService _expenseService;

  @override
  void initState() {
    super.initState();
    _collectionService = Provider.of<CollectionService>(context, listen: false);
    _expenseService = Provider.of<ExpenseService>(context,listen: false);

  }


  @override
  void dispose() {
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context,settingsService , child){
        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: FractionallySizedBox(
            heightFactor: 0.8,
            child:  ListView.builder(
              itemCount: widget.collections.length,
              itemBuilder: (context, index) {
                final collection = widget.collections[index];
                final collectionCost = collection.expenseList.fold(0.0 , (act , cost) => act + cost.price );
                final collectionItems = collection.expenseList.fold('' ,(act,str) => act  + str.name + ',' );
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Material(
                    elevation: settingsService.getElevation() ?  8 : 0,
                    child: ListTile(
                      onTap: (){
                        WarningDialog.showWarning(context: context,
                            title: 'Confirm',
                            message: 'Are you sure to add collection ${collection.name}?',
                            onConfirmed: () async {
                              int status = await _expenseService.createCollectionExpense(expenses: collection.expenseList, expenseDate: widget.expenseDate);
                              if(status == 0){
                                MessageWidget.showToast(context: context, message: 'Collection added successfully',status: 1);

                              }
                              else if(status > 0){
                                MessageWidget.showToast(context: context, message:'${status} expenses exceeded their limits and were skipped.' );
                              }
                              else{
                                MessageWidget.showToast(context: context, message: 'Failed to add collection',status: 0);
                              }
                              Navigator.pop(context);
                            }
                        );
                      },
                      title: Text(collection.name),
                      trailing: Text('₹${collectionCost.toStringAsFixed(2)}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if(collection.description!.length > 0 )
                            Text('${collection.description}',
                              style: TextStyle(fontSize: 12),),
                          Text(collectionItems , style: TextStyle(fontSize: 10),)
                        ],
                      ),
                    ),
                  ),
                );

              },
            ),
          ),
        );
      }

    );
  }
}
