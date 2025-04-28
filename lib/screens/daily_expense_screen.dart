import 'package:expense_log/models/expense.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/screens/expense_type_screen.dart';
import 'package:expense_log/screens/home_screen.dart';
import 'package:expense_log/services/collection_service.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/report_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/widgets/expense_form.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:expense_log/widgets/view_collection_modal.dart';
import 'package:expense_log/widgets/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../models/collection.dart';

class DailyExpenseScreen extends StatefulWidget {
  const DailyExpenseScreen({super.key});

  @override
  State<DailyExpenseScreen> createState() => _DailyExpenseScreenState();
}

class _DailyExpenseScreenState extends State<DailyExpenseScreen> {
  late UiService _uiService;
  late ExpenseService _expenseService;
  late CollectionService _collectionService;
  late SettingsService _settingsService;
  late ReportService _reportService;
  late List<Collection> availableCollections;
  String? expenseType;
  final ValueNotifier<DateTime> _selectedDateNotifier =
      ValueNotifier<DateTime>(DateTime.now());
  double totalExpense = 0.0;
  Map<int, Expense2> deleteList = {};
  late Map<String, double> _metricsData = {};
  bool groupByType = false;

  @override
  void initState() {
    super.initState();
    _uiService = Provider.of<UiService>(context, listen: false);
    _expenseService = Provider.of<ExpenseService>(context, listen: false);
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _collectionService = Provider.of<CollectionService>(context, listen: false);
    _reportService = Provider.of<ReportService>(context, listen: false);
    setState(() {
      availableCollections = _collectionService.getCollections();
    });
    totalExpense =
        _expenseService.selectedDayTotalExpense(_selectedDateNotifier.value);
    _metricsData = _expenseService.getMetrics('This month', 'By type', []);
    _selectedDateNotifier.addListener(() {
      setState(() {
        _metricsData = _expenseService.getMetrics('This month', 'By type', []);
        totalExpense = _expenseService
            .selectedDayTotalExpense(_selectedDateNotifier.value);
        deleteList.clear();
      });
    });
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImageAndRecognizeText() async {
    final XFile? imageFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (imageFile == null) return;

    final inputImage = InputImage.fromFilePath(imageFile.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    debugPrint('--- Extracted Text ---');
    for (TextBlock block in recognizedText.blocks) {
      debugPrint(block.text);
    }

    textRecognizer.close();
  }

  @override
  void dispose() {
    super.dispose();
    _selectedDateNotifier.dispose();
  }

  Widget buildExpenseTile(Expense2 expOfDay, {bool showType = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Material(
        elevation: _settingsService.getElevation() ? 4 : 0,
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).cardColor,
        child: ListTile(
          leading: deleteList.isNotEmpty
              ? Icon(
                  deleteList.containsKey(expOfDay.id)
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: deleteList.containsKey(expOfDay.id)
                      ? Colors.green
                      : Colors.grey,
                )
              : null,
          onTap: () async {
            if (deleteList.isNotEmpty) {
              setState(() {
                if (deleteList.containsKey(expOfDay.id)) {
                  deleteList.remove(expOfDay.id);
                } else {
                  deleteList[expOfDay.id] = expOfDay;
                }
              });
            } else {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => ExpenseForm(
                  expenseDate: _selectedDateNotifier.value,
                  expense: expOfDay,
                ),
              );
              if (result == true) {
                setState(() {
                  totalExpense = _expenseService
                      .selectedDayTotalExpense(_selectedDateNotifier.value);
                  _metricsData =
                      _expenseService.getMetrics('This month', 'By type', []);
                });
              }
            }
          },
          onLongPress: () {
            setState(() {
              if (!deleteList.containsKey(expOfDay.id)) {
                deleteList[expOfDay.id] = expOfDay;
              }
            });
          },
          title: Text(
            expOfDay.name,
            style: const TextStyle(
              fontSize: 18,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          subtitle: showType
              ? Text(
                  expOfDay.expenseType.name,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w100),
                )
              : null,
          trailing: Text(
            expOfDay.price.toString(),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            if (_selectedDateNotifier.value.year == DateTime.now().year &&
                _selectedDateNotifier.value.month == DateTime.now().month &&
                _selectedDateNotifier.value.day == DateTime.now().day) {
              MessageWidget.showToast(
                  context: context,
                  message: 'Cannot able to set daily expense for future dates',
                  status: 0);
            } else {
              setState(() {
                _selectedDateNotifier.value =
                    _selectedDateNotifier.value.add(const Duration(days: 1));
              });
            }
          } else if (details.primaryVelocity! > 0) {
            setState(() {
              _selectedDateNotifier.value =
                  _selectedDateNotifier.value.subtract(const Duration(days: 1));
            });
          }
        },
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDateNotifier.value = _selectedDateNotifier
                            .value
                            .subtract(const Duration(days: 1));
                      });
                    },
                    padding: const EdgeInsets.all(20.0),
                    icon: const Icon(Icons.arrow_back_ios)),
                ValueListenableBuilder<DateTime>(
                    valueListenable: _selectedDateNotifier,
                    builder: (context, selectedDate, _) {
                      return TextButton(
                          onPressed: () async {
                            DateTime pickDate = await _uiService.selectDate(
                                context,
                                last: DateTime.now(),
                                current: _selectedDateNotifier.value);
                            setState(() {
                              _selectedDateNotifier.value = pickDate;
                            });
                          },
                          child: Text(
                            _uiService.displayDay(_selectedDateNotifier.value),
                            style: const TextStyle(
                                // color: Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.w700),
                          ));
                    }),
                IconButton(
                    onPressed: () {
                      if (_selectedDateNotifier.value.year ==
                              DateTime.now().year &&
                          _selectedDateNotifier.value.month ==
                              DateTime.now().month &&
                          _selectedDateNotifier.value.day ==
                              DateTime.now().day) {
                        MessageWidget.showToast(
                            context: context,
                            message:
                                'Cannot able to set daily expense for future dates',
                            status: 0);
                      } else {
                        setState(() {
                          _selectedDateNotifier.value = _selectedDateNotifier
                              .value
                              .add(const Duration(days: 1));
                        });
                      }
                    },
                    padding: const EdgeInsets.all(20.0),
                    icon: const Icon(Icons.arrow_forward_ios))
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _settingsService.groupExpByType(),
                        onChanged: (value) {
                          setState(() async {
                            await _settingsService.setGrpExpByType(value!);
                          });
                        },
                      ),
                      const Text("Group by Type"),
                    ],
                  ),
                  ValueListenableBuilder(
                      valueListenable: _selectedDateNotifier,
                      builder: (context, date, _) {
                        if (deleteList.isNotEmpty) {
                          return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                WarningDialog.showWarning(
                                    context: context,
                                    title: 'Warning',
                                    message:
                                        'Are you sure to delete selected ${deleteList.length} expenses?',
                                    onConfirmed: () {
                                      _expenseService.deleteExpense(deleteList);
                                      setState(() {
                                        deleteList.clear();
                                        totalExpense = _expenseService
                                            .selectedDayTotalExpense(
                                                _selectedDateNotifier.value);
                                        _metricsData = _expenseService
                                            .getMetrics(
                                                'This month', 'By type', []);
                                      });
                                    },
                                    onCancelled: () {
                                      setState(() {
                                        deleteList.clear();
                                        totalExpense = _expenseService
                                            .selectedDayTotalExpense(
                                                _selectedDateNotifier.value);
                                        _metricsData = _expenseService
                                            .getMetrics(
                                                'This month', 'By type', []);
                                      });
                                      Navigator.pop(context);
                                    });
                              },
                              child: Text(
                                'Delete (${deleteList.length})',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ));
                        } else {
                          return Text(
                            "₹ ${totalExpense.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          );
                        }
                      })
                ],
              ),
            ),
            Expanded(
                child: ValueListenableBuilder(
              valueListenable: Hive.box<Expense2>('expense2Box').listenable(),
              builder: (context, Box<Expense2> box, _) {
                final expenseOfTheDate = _expenseService
                    .getExpensesOfTheDay(_selectedDateNotifier.value);
                if (expenseOfTheDate.isEmpty) {
                  return Column(
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
                        style: TextStyle(),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }

                if (_settingsService.groupExpByType()) {
                  // Group by type
                  Map<String, List<Expense2>> grpWithType = {};
                  for (var expense in expenseOfTheDate) {
                    final type = expense.expenseType.name;
                    if (grpWithType.containsKey(type)) {
                      grpWithType[type]!.add(expense);
                    } else {
                      grpWithType[type] = [expense];
                    }
                  }

                  return ListView(
                    children: grpWithType.entries.expand((entry) {
                      final type = entry.key;
                      final expenses = entry.value;
                      double typeTotal =
                          expenses.fold<double>(0.0, (sum, e) => sum + e.price);

                      return [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                type,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              Text(
                                "₹ ${typeTotal.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).primaryColor,
                                ),
                              )
                            ],
                          ),
                        ),
                        ...expenses
                            .map((expOfDay) =>
                                buildExpenseTile(expOfDay, showType: false))
                            .toList(),
                      ];
                    }).toList(),
                  );
                } else {
                  // Normal flat list
                  return ListView(
                    children: expenseOfTheDate
                        .map((expOfDay) => buildExpenseTile(expOfDay))
                        .toList(),
                  );
                }
              },
            )),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.symmetric(vertical: 50, horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // FloatingActionButton(onPressed: _pickImageAndRecognizeText,
            //   child: Icon(Icons.document_scanner_outlined),
            //   tooltip: 'Bill',
            // ),
            if (_expenseService
                .getExpensesOfTheDay(_selectedDateNotifier.value)
                .isNotEmpty)
              FloatingActionButton(
                onPressed: () async {
                  WarningDialog.showWarning(
                      context: context,
                      title: 'Daily Expense Report',
                      message:
                          'Proceed to download report for ${_uiService.displayDay(_selectedDateNotifier.value)}',
                      onConfirmed: () async {
                        MessageWidget.showToast(
                            context: context,
                            message: 'Downloading in progress...');
                        await _reportService.prepareDailyExpenseReport(
                            _expenseService.getExpensesOfTheDay(
                                _selectedDateNotifier.value));
                      });
                },
                child: Icon(Icons.print),
                tooltip: 'Daily Expense Report',
              ),
            SizedBox(
              height: 10,
            ),
            if (availableCollections.isNotEmpty)
              FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                      isScrollControlled: true,
                      showDragHandle: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      context: context,
                      builder: (context) {
                        return ViewCollectionModal(
                          collections: availableCollections,
                          expenseDate: _selectedDateNotifier.value,
                        );
                      });
                },
                child: Icon(Icons.collections_bookmark_rounded),
                tooltip: 'Load from Collection',
              ),
            SizedBox(
              height: 10,
            ),
            FloatingActionButton(
              tooltip: 'Copy',
              onPressed: () async {
                DateTime? copyFromDate = await _uiService.selectDate(context,
                    last: DateTime.now(),
                    current: _selectedDateNotifier.value,
                    title: 'Select a date to copy expenses');
                WarningDialog.showWarning(
                    context: context,
                    title: 'Confirm',
                    message: 'Are you '
                        'sure to copy expenses of '
                        '${_uiService.displayDay(copyFromDate)} '
                        'to ${_uiService.displayDay(_selectedDateNotifier.value)}',
                    onConfirmed: () async {
                      if (copyFromDate != null) {
                        List<String> getExceedList = [];
                        int createCopiedExpenses =
                            await _expenseService.copyAndSaveExpenses(
                                copyFromDate: copyFromDate,
                                pasteToDate: _selectedDateNotifier.value,
                                exceedList: getExceedList);
                        if (createCopiedExpenses == 0) {
                          setState(() {
                            totalExpense =
                                _expenseService.selectedDayTotalExpense(
                                    _selectedDateNotifier.value);
                            _metricsData = _expenseService
                                .getMetrics('This month', 'By type', []);
                          });
                          MessageWidget.showToast(
                              context: context,
                              message: 'Copied successfully',
                              status: 1);
                          if (getExceedList.isNotEmpty) {
                            WarningDialog.showWarning(
                                context: context,
                                title: 'Info',
                                message: getExceedList.join('\n'),
                                onConfirmed: () {});
                          }
                        } else if (createCopiedExpenses == -1) {
                          MessageWidget.showToast(
                              context: context,
                              message: 'No expenses in the selected date!',
                              status: 0);
                        } else if (createCopiedExpenses > 0) {
                          MessageWidget.showToast(
                              context: context,
                              message:
                                  '${createCopiedExpenses} expenses exceeded their limits and were skipped.');
                        } else if (createCopiedExpenses == -2) {
                          MessageWidget.showToast(
                              context: context,
                              message: 'Error when copying expenses',
                              status: 0);
                        }
                      }
                    });
              },
              child: const Icon(Icons.copy),
            ),
            SizedBox(
              height: 10,
            ),
            FloatingActionButton(
              tooltip: 'Create',
              onPressed: () async {
                final getTypes = _expenseService.getExpenseTypes();
                if (getTypes.isNotEmpty) {
                  final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => ExpenseForm(
                          expenseDate: _selectedDateNotifier.value));
                  if (result == true) {
                    setState(() {
                      totalExpense = _expenseService
                          .selectedDayTotalExpense(_selectedDateNotifier.value);
                      _metricsData = _expenseService
                          .getMetrics('This month', 'By type', []);
                    });
                  }
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomeScreen(
                                initialIndex: 1,
                              )));
                  MessageWidget.showToast(
                      context: context,
                      message:
                          'Create your expense type for adding your expense and keep track of it');
                }
              },
              child: const Icon(
                Icons.add,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
