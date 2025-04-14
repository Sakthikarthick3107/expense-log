import 'package:expense_log/widgets/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/collection.dart';
import '../models/expense2.dart';
import '../services/collection_service.dart';
import '../services/settings_service.dart';
import 'expense_form.dart';
import 'message_widget.dart';

class CollectionFormModal extends StatefulWidget {

  Collection? collection;

   CollectionFormModal({super.key , this.collection});

  @override
  State<CollectionFormModal> createState() => _CollectionFormModalState();
}

class _CollectionFormModalState extends State<CollectionFormModal> {

  final _formKey = GlobalKey<FormState>();
  late SettingsService _settingsService;
  late CollectionService _collectionService;
  final ValueNotifier<List<Expense2>> addedExpenseNotifier = ValueNotifier<List<Expense2>>([]);
  late TextEditingController _nameController = TextEditingController();
  late TextEditingController _descriptionController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _collectionService = Provider.of<CollectionService>(context, listen: false);
    _nameController = TextEditingController(text: widget.collection?.name ?? '');
    _descriptionController = TextEditingController(text:  widget.collection?.description ?? '');
    addedExpenseNotifier.value = List.from(widget.collection?.expenseList ?? []);

  }

  @override
  void dispose(){
    super.dispose();
    addedExpenseNotifier.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color:  Theme.of(context).scaffoldBackgroundColor,
      child: FractionallySizedBox(

        heightFactor: 0.9,
        child: Form(
          key: _formKey,
          child: Container(

            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text(
                      '${widget.collection != null ? 'Edit' : 'New'} Collection',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                   ),
                     if(widget.collection != null)
                       IconButton(onPressed: (){
                         WarningDialog.showWarning(context: context,
                             title: 'Warning',
                             message: 'Are you sure to delete collection ${widget.collection?.name}?',
                             onConfirmed: (){
                               _collectionService.deleteCollection(widget.collection!.id);
                               Navigator.pop(context);
                             }

                         );
                       },
                           tooltip: 'Delete Collection',
                           icon: Icon(Icons.delete , color: Colors.red,))
                   ],
                 ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Collection Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is mandatory';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                    validator: (value) {
                      if (addedExpenseNotifier.value.isEmpty) {
                        return 'Add expense to the collection';
                      }
                      return null;
                    }

                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ValueListenableBuilder<List<Expense2>>(
                    valueListenable: addedExpenseNotifier,
                    builder: (context, addedExpenses, _) {
                      if (addedExpenses.isEmpty) {
                        return const Center(
                          child: Text('No expenses added yet.'),
                        );
                      }
                      return ListView.builder(
                        itemCount: addedExpenses.length,
                        itemBuilder: (context, index) {
                          final exp = addedExpenses[index];
                          return ListTile(
                            title: Text(
                                '${exp.name} - ₹${exp.price.toStringAsFixed(2)}'),
                            subtitle: Text('Type: ${exp.expenseType.name}'),
                            trailing: IconButton(
                              onPressed: () {
                                addedExpenseNotifier.value =
                                    List.from(addedExpenseNotifier.value
                                      ..removeAt(index));
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      Expense2? addExpense = await showDialog<Expense2>(
                        context: context,
                        builder: (_) => ExpenseForm(
                          expenseDate: DateTime.now(),
                          isFromCollection: true,
                        ),
                      );
                      if (addExpense != null) {
                        addedExpenseNotifier.value =
                            List.from(addedExpenseNotifier.value..add(addExpense));
                      }
                    },
                    child: const Text('Add Expense'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                       if (_formKey.currentState?.validate() ?? false) {
                        final name = _nameController.text;
                        final description  = _descriptionController.text;
                        final expenseList = addedExpenseNotifier.value.toList();

                        Collection newCollection = Collection(
                          id:widget.collection?.id ?? await _settingsService.getBoxKey('collectionId'),
                          name: name,
                          description: description,
                          expenseList: expenseList,
                          created: widget.collection?.created ?? DateTime.now(),
                          updated: widget.collection?.created != null ? DateTime.now() : null
                        );
                        int status = await _collectionService.createCollection(newCollection);
                        final action = widget.collection != null ? 'edited' : 'created';
                        if (status == 1) {
                          Navigator.pop(context);
                          MessageWidget.showToast(
                              context: context, message: 'Successfully $action collection', status: 1);

                          addedExpenseNotifier.value.clear();
                        } else {
                          Navigator.pop(context);
                          MessageWidget.showToast(
                              context: context, message: 'Failed to create collection', status: 0);
                        }
                      }
                    },
                    child:  Text('${widget.collection != null ? 'Edit' : 'Create'} Collection'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
