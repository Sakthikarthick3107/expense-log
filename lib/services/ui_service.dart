
import 'package:expense_log/models/expense.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class UiService{


  Future<DateTime> selectDate(BuildContext context) async{
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        firstDate: DateTime(1990),
        lastDate: DateTime(2200),
        initialDate: DateTime.now()
    );
    return pickedDate!;
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