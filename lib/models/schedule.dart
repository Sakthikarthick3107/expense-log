import 'package:expense_log/models/expense2.dart';
import 'package:hive_flutter/adapters.dart';
part 'schedule.g.dart';

@HiveType(typeId: 7)
enum ScheduleType {
  @HiveField(0)
  Reminder,
  @HiveField(1)
  AutoExpense,
}

@HiveType(typeId: 8)
enum RepeatOption {
  @HiveField(0)
  Once,
  @HiveField(1)
  Everyday,
  @HiveField(2)
  Weekdays,
  @HiveField(3)
  Weekends,
  @HiveField(4)
  CustomDays,
}

@HiveType(typeId: 10)
enum CustomByType {
  @HiveField(0)
  Week,
  @HiveField(1)
  Month,
}

@HiveType(typeId: 9)
class Schedule {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  ScheduleType scheduleType;

  @HiveField(4)
  List<Expense2>? data;

  @HiveField(5)
  int hour;

  @HiveField(6)
  int minute;

  @HiveField(7)
  RepeatOption repeatOption;

  @HiveField(8)
  List<int>? customDays;

  @HiveField(9)
  bool isActive;

  @HiveField(10)
  DateTime? lastTriggeredTime;

  @HiveField(11)
  CustomByType? customByType;

  @HiveField(12)
  DateTime? nextTriggerAt;

  Schedule(
      {required this.id,
      required this.name,
      required this.description,
      required this.scheduleType,
      this.data,
      required this.hour,
      required this.minute,
      required this.repeatOption,
      this.customDays,
      required this.isActive,
      this.lastTriggeredTime,
      this.customByType,
      this.nextTriggerAt});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'scheduleType': scheduleType.index,
      'data': data?.map((e) => e.toJson()).toList(),
      'hour': hour,
      'minute': minute,
      'repeatOption': repeatOption.index,
      'customDays': customDays,
      'isActive': isActive,
      'lastTriggeredTime': lastTriggeredTime?.toIso8601String(),
      'customByType': customByType?.index,
      'nextTriggerAt': nextTriggerAt
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      scheduleType: ScheduleType.values[json['scheduleType']['index']],
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => Expense2.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : null,
      hour: json['hour'],
      minute: json['minute'],
      repeatOption: RepeatOption.values[json['repeatOption']['index']],
      customDays: json['customDays'] != null
          ? List<int>.from(json['customDays'])
          : null,
      isActive: json['isActive'],
      lastTriggeredTime: json['lastTriggeredTime'] != null
          ? DateTime.parse(json['lastTriggeredTime'])
          : null,
      customByType: CustomByType.values[json['customByType']['index']],
      nextTriggerAt: json['nextTriggerAt'] != null
          ? DateTime.parse(json['nextTriggerAt'])
          : null,
    );
  }
}
