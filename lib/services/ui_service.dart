
import 'package:expense_log/models/expense.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class UiService{


  Future<DateTime> selectDate(BuildContext context,{String? title ,DateTime? last  , DateTime? current}) async{
    final DateTime? pickedDate = await showDatePicker(
      helpText: title ?? 'Select Date' ,
        context: context,
        firstDate: DateTime(1990),
        lastDate: last != null ? last :  DateTime(2200),
        initialDate: current != null ? current : DateTime.now(),

    );
    return pickedDate!;
  }

  Future<DateTimeRange> selectedDuration(BuildContext context , {DateTimeRange? lastSelectedRange}) async{
    final DateTime now = DateTime.now();
    final DateTimeRange? selectRange = await showDateRangePicker(
        context: context,
        initialEntryMode: DatePickerEntryMode.input,
        firstDate: DateTime(1990),
        lastDate: now,
      initialDateRange: lastSelectedRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now)
    );

    return selectRange!;
  }

  String getTimeOfDay(){
    final now = DateTime.now();
    final hour = now.hour;
    if (hour >= 5 && hour < 9) {
      return "Morning";
    } else if (hour >= 9 && hour < 12) {
      return "Early Noon";
    } else if (hour >= 12 && hour < 17) {
      return "Afternoon";
    } else if (hour >= 17 && hour < 21) {
      return "Evening";
    } else {
      return "Night";
    }
  }

  String displayDay(DateTime selectedDate){
      final now = DateTime.now();
      final today = DateTime(now.year,now.month,now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      bool isSameDate(DateTime date1, DateTime date2) {
        return date1.year == date2.year &&
            date1.month == date2.month &&
            date1.day == date2.day;
      }

      if(isSameDate(today, selectedDate)){
        return 'Today';
      }
      else if(isSameDate(yesterday, selectedDate)){
        return 'Yesterday';
      }
      else if(isSameDate(tomorrow, selectedDate)){
        return 'Tomorrow';
      }
      else if(selectedDate.isAfter(today.subtract(Duration(days: now.weekday - 1))) && selectedDate.isBefore(today.add(Duration(days: 7 - now.weekday)))){
        return DateFormat('EEEE').format(selectedDate);
      }
      else if(selectedDate.year==now.year){
        return DateFormat('dd MMMM').format(selectedDate);
      }

      return DateFormat('dd MMMM yyyy').format(selectedDate);
  }



}