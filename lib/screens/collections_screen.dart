import 'package:expense_log/services/collection_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/widgets/collection_form_modal.dart';
import 'package:expense_log/widgets/expense_form.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

import '../models/collection.dart';
import '../models/expense2.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {

  late SettingsService _settingsService;
  late CollectionService _collectionService;

  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<List<Expense2>> addedExpenseNotifier = ValueNotifier<List<Expense2>>([]);
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _collectionService = Provider.of<CollectionService>(context, listen: false);
  }

  @override
  void dispose(){
    super.dispose();
    addedExpenseNotifier.value.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
        builder: (context,settingsService , child){
          return Scaffold(
            body: Container(
              padding: EdgeInsets.all(10),
              child: ValueListenableBuilder<Box<Collection>>(
                valueListenable: Hive.box<Collection>('collectionBox').listenable(),
                builder: (context, box, _) {
                  final allCollections = _collectionService.getCollections();

                  if (allCollections.isEmpty) {
                    return const Center(child: Text('Create a collection'));
                  }

                  return ListView.builder(
                    itemCount: allCollections.length,
                    itemBuilder: (context, index) {
                      final collection = allCollections[index];
                      final collectionCost = collection.expenseList.fold(0.0 , (act , cost) => act + cost.price );
                      final collectionItems = collection.expenseList.fold('' ,(act,str) => act  + str.name + ',' );
                      return Container(
                        margin: EdgeInsets.only(bottom: 4),
                        child: Material(
                          elevation : settingsService.getElevation() ? 8  : 0,
                          borderRadius: BorderRadius.circular(10),
                          child: ListTile(
                            title: Text(collection.name),
                            trailing: Text('₹${collectionCost.toStringAsFixed(2)}'),
                            subtitle: Text('${collection.description!.length > 0 ? collection.description : collectionItems}',

                              style: TextStyle(fontSize: 12),),
                            onTap: () {
                              showModalBottomSheet(
                                isScrollControlled: true,
                                showDragHandle: true,
                                barrierColor: Colors.black,
                                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                context: context,
                                builder: (context) {
                                  return  CollectionFormModal(collection: collection);
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            floatingActionButton: Container(
              margin: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
              child: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    isScrollControlled: true,
                    showDragHandle: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    context: context,
                    builder: (context) {
                      return  CollectionFormModal();
                    },
                  );
                },
                tooltip: 'Create new collection',
                child: const Icon(
                  Icons.add,
                  size: 30,
                ),
              ),
            ),
          );
        }

    );
  }
}
