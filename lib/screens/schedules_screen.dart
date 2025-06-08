import 'package:expense_log/screens/create_schedule.dart';
import 'package:expense_log/services/audit_log_service.dart';
import 'package:expense_log/services/schedule_service.dart';
import 'package:expense_log/models/schedule.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  ScheduleType? selectedScheduleType;

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleService>(
      builder: (context, scheduleService, _) {
        List<Schedule> schedules = scheduleService.getSchedules();

        schedules = selectedScheduleType == null
            ? schedules
            : schedules
                .where(
                    (schedule) => schedule.scheduleType == selectedScheduleType)
                .toList();

        return Consumer<SettingsService>(
            builder: (context, settingsService, _) {
          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Schedules', style: TextStyle(fontSize: 16)),
                  SizedBox(
                    height: 2,
                  ),
                  RichText(
                    softWrap: true,
                    text: const TextSpan(
                      text:
                          'Enable \'Alarms & Reminders\' for ExpenseLog in Settings to use this feature effectively',
                      style:
                          TextStyle(fontSize: 8, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ScheduleType?>(
                      value: selectedScheduleType,
                      hint: Text('Filter', style: TextStyle(fontSize: 14)),
                      items: [
                        DropdownMenuItem<ScheduleType?>(
                          value: null, // For "All"
                          child: Text('All', style: TextStyle(fontSize: 14)),
                        ),
                        ...ScheduleType.values.map((type) {
                          return DropdownMenuItem<ScheduleType?>(
                            value: type,
                            child: Text(
                              type.toString().split('.').last,
                              style: TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedScheduleType = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            body: schedules.isEmpty
                ? Center(child: Text('No schedules available.'))
                : ListView.builder(
                    itemCount: schedules.length,
                    itemBuilder: (context, index) {
                      final schedule = schedules[index];
                      return Container(
                          margin: EdgeInsets.all(4),
                          child: Material(
                              elevation: settingsService.getElevation() ? 4 : 0,
                              borderRadius: BorderRadius.circular(10),
                              color: Theme.of(context).cardColor,
                              child: ListTile(
                                  onTap: schedule.isActive
                                      ? () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      CreateScheduleScreen(
                                                          schedule: schedule)));
                                        }
                                      : () {
                                          MessageWidget.showToast(
                                              context: context,
                                              message:
                                                  'Restricted to edit Deactivated Schedules',
                                              status: 0);
                                        },
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(schedule.name,
                                          style: TextStyle(fontSize: 14)),
                                      Transform.scale(
                                        scale: 0.6,
                                        child: Chip(
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(30))),
                                          label: Text(
                                            schedule.repeatOption.name,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .displayLarge!
                                                    .color),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${TimeOfDay(hour: schedule.hour, minute: schedule.minute).format(context)} - ${schedule.description}',
                                        style: TextStyle(fontSize: 10),
                                      ),
                                      Text(
                                          '${schedule.nextTriggerAt != null ? 'Next Scheduled - ${DateFormat.yMd().add_jm().format(schedule.nextTriggerAt!)}' : "Not Scheduled"}',
                                          style: TextStyle(fontSize: 8))
                                    ],
                                  ),
                                  trailing: Transform.scale(
                                    scale: 0.7,
                                    child: Switch(
                                      value: schedule.isActive,
                                      onChanged: (bool value) {
                                        scheduleService.handleActivation(
                                            schedule.id, value);

                                        final notify =
                                            'Schedule - ${schedule.name} ${value ? 'activated' : 'deactivated'}';
                                        MessageWidget.showToast(
                                            context: context, message: notify);
                                        AuditLogService.writeLog(notify);
                                      },
                                    ),
                                  ))));
                    },
                  ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateScheduleScreen()));
              },
              child: Icon(Icons.add),
            ),
          );
        });
      },
    );
  }
}
