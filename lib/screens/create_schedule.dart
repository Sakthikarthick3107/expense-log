import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/schedule.dart';
import 'package:expense_log/services/audit_log_service.dart';
import 'package:expense_log/services/schedule_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/widgets/expense_form.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:expense_log/widgets/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreateScheduleScreen extends StatefulWidget {
  final Schedule? schedule;

  const CreateScheduleScreen({super.key, this.schedule});

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String description = '';
  ScheduleType scheduleType = ScheduleType.Reminder;
  RepeatOption repeatOption = RepeatOption.Once;
  List<int> customDays = [];
  List<Expense2> selectedExpenses = [];
  TimeOfDay selectedTime = TimeOfDay.now();
  bool isActive = true;
  CustomByType? customDaysType = CustomByType.Week;

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      name = widget.schedule!.name;
      description = widget.schedule!.description;
      scheduleType = widget.schedule!.scheduleType;
      repeatOption = widget.schedule!.repeatOption;
      customDays = widget.schedule!.customDays ?? [];
      selectedExpenses = widget.schedule!.data ?? [];
      selectedTime = TimeOfDay(
          hour: widget.schedule!.hour, minute: widget.schedule!.minute);
      isActive = widget.schedule!.isActive;
      customDaysType = widget.schedule!.customByType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleService>(builder: (context, _scheduleService, _) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
              '${widget.schedule != null ? 'Edit Schedule' : 'Create Schedule'}'),
          actions: [
            if (widget.schedule != null)
              TextButton(
                  onPressed: () {
                    WarningDialog.showWarning(
                        title: 'Confirm',
                        message: 'Are you sure to delete Schedule - ${name}?',
                        context: context,
                        onConfirmed: () async {
                          final notify =
                              'Schedule ${name} deleted successfully!';
                          await _scheduleService
                              .deleteSchedule(widget.schedule!.id);
                          MessageWidget.showToast(
                              context: context, message: notify, status: 1);
                          AuditLogService.writeLog(notify);
                          Navigator.pop(context);
                        });
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  )),
            SizedBox(
              width: 10,
            )
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(labelText: 'Name'),
                onChanged: (value) => name = value,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: description,
                decoration: InputDecoration(labelText: 'Description'),
                onChanged: (value) => description = value,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<ScheduleType>(
                value: scheduleType,
                decoration: InputDecoration(labelText: 'Schedule Type'),
                items: ScheduleType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type.toString().split('.').last,
                      style: TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    scheduleType = value!;
                  });
                },
              ),
              if (scheduleType == ScheduleType.AutoExpense)
                Wrap(
                  spacing: 0,
                  runSpacing: 0,
                  children: [
                    if (selectedExpenses.isEmpty) Text('Add expenses'),
                    ...selectedExpenses.map((expense) => Transform.scale(
                        scale: 0.7,
                        child: Chip(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30))),
                          label: Text(
                              '${expense.name} - ${expense.price.toStringAsFixed(0)}'),
                          onDeleted: () {
                            setState(() {
                              selectedExpenses.remove(expense);
                            });
                          },
                        ))),
                    Transform.scale(
                      scale: 0.7,
                      child: ActionChip(
                        label: Icon(Icons.add),
                        onPressed: () async {
                          Expense2? addExpense = await showDialog<Expense2>(
                              context: context,
                              builder: (_) => ExpenseForm(
                                    expenseDate: DateTime.now(),
                                    isFromCollection: true,
                                  ));
                          if (addExpense != null) {
                            setState(() {
                              selectedExpenses.add(addExpense);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<RepeatOption>(
                      value: repeatOption,
                      decoration: InputDecoration(labelText: 'Repeat Option'),
                      items: RepeatOption.values.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option.toString().split('.').last,
                              style: TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          repeatOption = value!;
                          if (repeatOption != RepeatOption.CustomDays) {
                            customDaysType = CustomByType.Week;
                            customDays.clear();
                          }
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  if (repeatOption == RepeatOption.CustomDays)
                    Expanded(
                      child: DropdownButtonFormField<CustomByType>(
                        value: customDaysType,
                        decoration: InputDecoration(labelText: 'Custom By'),
                        items: CustomByType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toString().split('.').last,
                                style: TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            customDaysType = value!;
                            customDays.clear();
                          });
                        },
                      ),
                    ),
                ],
              ),

              if (repeatOption == RepeatOption.CustomDays)
                Wrap(
                  spacing: 1,
                  children: customDaysType == CustomByType.Week
                      ? List.generate(7, (index) {
                          final dayNames = [
                            'Sun',
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat'
                          ];
                          final isSelected = customDays.contains(index);
                          return Transform.scale(
                            scale: 0.7,
                            child: FilterChip(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30))),
                              label: Text(dayNames[index]),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    customDays.add(index);
                                  } else {
                                    customDays.remove(index);
                                  }
                                });
                              },
                            ),
                          );
                        })
                      : List.generate(31, (index) {
                          final dayNumber = index + 1;
                          final isSelected = customDays.contains(dayNumber);
                          return Transform.scale(
                            scale: 0.7,
                            child: FilterChip(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30))),
                              label: Text('$dayNumber'),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    customDays.add(dayNumber);
                                  } else {
                                    customDays.remove(dayNumber);
                                  }
                                });
                              },
                            ),
                          );
                        }),
                ),

              ListTile(
                title: Text('Time: ${selectedTime.format(context)}'),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedTime = picked;
                    });
                  }
                },
              ),
              // SwitchListTile(
              //   title: Text('Active'),
              //   value: isActive,
              //   onChanged: (value) {
              //     setState(() {
              //       isActive = value;
              //     });
              //   },
              // ),
              // SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final settingsService =
                        Provider.of<SettingsService>(context, listen: false);
                    if (widget.schedule == null) {
                      // Create new schedule
                      final newSchedule = Schedule(
                        id: widget.schedule?.id ??
                            await settingsService
                                .getBoxKey('scheduleId'), // better unique ID
                        name: name,
                        description: description,
                        scheduleType: scheduleType,
                        data: selectedExpenses,
                        hour: selectedTime.hour,
                        minute: selectedTime.minute,
                        repeatOption: repeatOption,
                        customDays: customDays.isEmpty ? null : customDays,
                        isActive: isActive,
                      );

                      await _scheduleService.createSchedule(newSchedule);
                    } else {
                      final editedSchedule = Schedule(
                          id: widget.schedule!.id,
                          name: name,
                          description: description,
                          scheduleType: scheduleType,
                          data: selectedExpenses,
                          hour: selectedTime.hour,
                          minute: selectedTime.minute,
                          repeatOption: repeatOption,
                          customDays: customDays.isEmpty ? null : customDays,
                          isActive: isActive,
                          customByType: customDaysType);

                      await _scheduleService.editSchedule(editedSchedule);
                    }

                    Navigator.pop(context);
                    var notify =
                        'Schedule - ${name} ${widget.schedule == null ? 'created' : 'edited'} successfully';
                    MessageWidget.showToast(
                        context: context, message: notify, status: 1);
                    AuditLogService.writeLog(notify);
                  }
                },
                child: Text(widget.schedule == null
                    ? 'Create Schedule'
                    : 'Save Changes'),
              ),
            ],
          ),
        ),
      );
    });
  }
}
