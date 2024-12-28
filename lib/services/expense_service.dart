import 'package:expense_log/models/expense.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ExpenseService{
    final _expenseTypeBox =Hive.box<ExpenseType>('expenseTypeBox');
    final _expenseBox2 = Hive.box<Expense2>('expense2Box');

    List<ExpenseType> getExpenseTypes() => _expenseTypeBox.values.toList();

    List<Expense2> getExpenses() => _expenseBox2.values.toList();

    bool ifExpenseTypeExist (ExpenseType type){
        final expenseTypes = _expenseTypeBox.values.toList();
        return expenseTypes.any((expType) => expType.name.toLowerCase() == type.name.toLowerCase() );
    }

    int createExpenseType(ExpenseType type) {
        final checkIfExist = _expenseTypeBox.get(type.id);
        if(checkIfExist == null){
            if(ifExpenseTypeExist(type)){
                return 0;
            }
            else{
                _expenseTypeBox.put(type.id, type);
                return 1;
            }
        }
        else{
            if(type.name.toLowerCase() != checkIfExist.name.toLowerCase()){
                if(ifExpenseTypeExist(type)){
                    return 0;
                }
            }
            _expenseTypeBox.put(type.id, type);
            _expenseBox2.values
                .where((expense) => expense.expenseType.id == type.id)
                .forEach((expense) => _expenseBox2.put(expense.id , expense.copyWith(expenseType: type)));
            return 1;
        }
    }

    int createExpense(Expense2 expense) {
        _expenseBox2.put(expense.id, expense);
        return 1;
    }

    void deleteExpense(Map<int,Expense2> expenses) => {
        expenses.forEach((id,expense){
            _expenseBox2.delete(expense.id);
        })
    };

    List<Expense2> getExpensesOfTheDay(DateTime selectedDate){
        return getExpenses().where((expense){
            DateTime expDate = expense.date;
            return expDate.year == selectedDate.year &&
                expDate.month == selectedDate.month &&
                expDate.day == selectedDate.day;
        }).toList();
    }

    double  selectedDayTotalExpense(DateTime selectedDate){
        final expenseOfTheDate = getExpensesOfTheDay(selectedDate);
       return expenseOfTheDate.fold(0.0 , (total,expense) => total +expense.price);
    }

    List<String> expenseTypesOfSelectedDuration(String duration){
        final expenseTypes = getExpenseTypes();
        final expenses = getExpenses();
        DateTime now = DateTime.now();
        DateTime startDate = DateTime(now.year,now.month,now.day);
        DateTime endDate = now;
        List<String> usedTypes = [];
        switch(duration){
            case 'This week':
                startDate = startDate.subtract(Duration(days: startDate.weekday % 7));
                endDate = startDate.add(Duration(days: 6));
                break;
            case 'Last week':
                startDate = startDate.subtract(Duration(days: (startDate.weekday + 7) % 7 + 7));
                endDate = startDate.add(Duration(days: 6));
                break;
            case 'This month':
                startDate = DateTime(now.year , now.month ,1);
                endDate = DateTime(now.year, now.month + 1, 0);
                break;
            case 'Last month':
                startDate = DateTime(now.year , now.month - 1 ,1);
                endDate = DateTime(now.year, now.month, 0);
                break;
        }

        for (var expenseType in expenseTypes) {
            double total = expenses.where((expense) =>
            expense.expenseType.id == expenseType.id &&
                !expense.date.isBefore(startDate) &&
                expense.date.isBefore(endDate.add(Duration(days: 1))))
                .fold(0.0, (sum, expense) => sum + expense.price);
            if (total != 0) {
                usedTypes.add(expenseType.name);
            }
        }
        return usedTypes;
    }

    Map<String,double> getMetrics(String duration , String metricBy , List<String> unselectedTypes){
        final expenseTypes = getExpenseTypes();
        final expenses = getExpenses();
        Map<String, double> metricData = {'Total': 0.0};
        DateTime now = DateTime.now();
        DateTime startDate = DateTime(now.year,now.month,now.day);
        DateTime endDate = now;

        switch(duration){
            case 'This week':
                startDate = startDate.subtract(Duration(days: startDate.weekday % 7));
                endDate = startDate.add(Duration(days: 6));
                break;
            case 'Last week':
                startDate = startDate.subtract(Duration(days: (startDate.weekday + 7) % 7 + 7));
                endDate = startDate.add(Duration(days: 6));
                break;
            case 'This month':
                startDate = DateTime(now.year , now.month ,1);
                endDate = DateTime(now.year, now.month + 1, 0);
                break;
            case 'Last month':
                startDate = DateTime(now.year , now.month - 1 ,1);
                endDate = DateTime(now.year, now.month, 0);
                break;
        }

        if (metricBy == 'By type') {

            for (var expenseType in expenseTypes) {
                double total = expenses.where((expense) =>
                expense.expenseType.id == expenseType.id &&
                    !expense.date.isBefore(startDate) &&
                    expense.date.isBefore(endDate.add(Duration(days: 1))) &&
                    !unselectedTypes.contains(expenseType.name))
                    .fold(0.0, (sum, expense) => sum + expense.price);

                if (total != 0) {
                    metricData[expenseType.name] = total;
                    metricData['Total'] = (metricData['Total'] ?? 0.0) + total;
                }
            }
        }

        else if (metricBy == 'By day') {
            UiService uiService = UiService();
            Map<DateTime, double> tempMetricsData = {};
            double overallTotal = 0.0;
            for (var expense in expenses.where((exp) => !unselectedTypes.contains(exp.expenseType.name) && !exp.date.isBefore(startDate) && exp.date.isBefore(endDate.add(Duration(days: 1))))) {
                DateTime day = DateTime(expense.date.year , expense.date.month,expense.date.day) ;
                tempMetricsData[day] = (tempMetricsData[day] ?? 0.0) + expense.price;
                overallTotal += expense.price;
            }
            List<DateTime> sortedDays = tempMetricsData.keys.toList();
            sortedDays.sort((a,b) => b.compareTo(a));
            Map<String, double> sortedMetricsData = {'Total': overallTotal};


            for (DateTime day in sortedDays) {
                String dayString = uiService.displayDay(day);
                double dailyTotal = tempMetricsData[day]!;
                sortedMetricsData[dayString] = dailyTotal;
            }
            metricData = sortedMetricsData;
        }

        return metricData;


    }

    Map<Map<String, double>,List< Map<String, double>>> getMetrics2(String duration , String metricBy , List<String> unselectedTypes){
        final expenseTypes = getExpenseTypes();
        final expenses = getExpenses();
        UiService uiService = UiService();
        Map<Map<String, double>,List< Map<String, double>>> fullMetrics = {};
        fullMetrics[{'Total': 0.0}] = [];

        DateTime now = DateTime.now();
        DateTime startDate = DateTime(now.year,now.month,now.day);
        DateTime endDate = now;

        switch(duration){
            case 'This week':
                startDate = startDate.subtract(Duration(days: startDate.weekday % 7));
                endDate = startDate.add(Duration(days: 6));
                break;
            case 'Last week':
                startDate = startDate.subtract(Duration(days: (startDate.weekday + 7) % 7 + 7));
                endDate = startDate.add(Duration(days: 6));
                break;
            case 'This month':
                startDate = DateTime(now.year , now.month ,1);
                endDate = DateTime(now.year, now.month + 1, 0);
                break;
            case 'Last month':
                startDate = DateTime(now.year , now.month - 1 ,1);
                endDate = DateTime(now.year, now.month, 0);
                break;
        }

        if (metricBy == 'By type') {

            for (var expenseType in expenseTypes) {
                var filterWithType = expenses.where((expense) =>
                    expense.expenseType.id == expenseType.id &&
                    !expense.date.isBefore(startDate) &&
                    expense.date.isBefore(endDate.add(Duration(days: 1))) &&
                        !unselectedTypes.contains(expenseType.name)
                );

                double total = filterWithType.fold(0.0, (sum, expense) => sum + expense.price);

                if (total != 0) {
                    Map<String, double> primaryMetric = {};

                    primaryMetric[expenseType.name] = total;

                    List<Map<String,double>> secondaryMetric = [];
                    Map<DateTime, double> secondaryTempMetric = {};
                    for(var expenseDate in filterWithType){
                        DateTime day = DateTime(expenseDate.date.year , expenseDate.date.month ,expenseDate.date.day) ;
                        secondaryTempMetric[day] = (secondaryTempMetric[day] ?? 0) + expenseDate.price;
                    }

                    List<DateTime> sortedDays = secondaryTempMetric.keys.toList();
                    sortedDays.sort((a,b) => b.compareTo(a));
                    for (DateTime day in sortedDays) {
                        String dayString = uiService.displayDay(day);
                        double dailyTotal = secondaryTempMetric[day]!;
                        secondaryMetric.add({dayString: dailyTotal});
                    }
                    fullMetrics[primaryMetric] = secondaryMetric;
                    if (fullMetrics.isNotEmpty) {
                        Map<String, double> primaryTempMetric = fullMetrics.keys.first;
                        primaryTempMetric['Total'] = (primaryTempMetric['Total'] ?? 0.0) + total;
                    }
                }
            }

        }

        else if (metricBy == 'By day') {

            Map<DateTime, double> primaryTempMetricsData = {};
            double overallTotal = 0.0;

            var filterWithDayLimit = expenses.where((exp) => !unselectedTypes.contains(exp.expenseType.name) && !exp.date.isBefore(startDate) && exp.date.isBefore(endDate.add(Duration(days: 1))));

            for (var expense in filterWithDayLimit) {
                DateTime day = DateTime(expense.date.year , expense.date.month,expense.date.day) ;
                primaryTempMetricsData[day] = (primaryTempMetricsData[day] ?? 0.0) + expense.price;
                overallTotal += expense.price;
            }
            List<DateTime> sortedDays = primaryTempMetricsData.keys.toList();
            sortedDays.sort((a,b) => b.compareTo(a));
            Map<String, double> sortedMetricsData = {'Total': overallTotal};


            for (DateTime day in sortedDays) {
                Map<String, double> primaryMetric = {};
                List<Map<String,double>> secondaryMetric = [];

                String dayString = uiService.displayDay(day);
                double dailyTotal = primaryTempMetricsData[day]!;
                primaryMetric[dayString] = dailyTotal;

                var todaysExpense = filterWithDayLimit.where((selected) =>
                        day.year == selected.date.year &&
                        day.month == selected.date.month &&
                        day.day == selected.date.day
                        );
                Map<String,double> tempSecMetric = {};

                for(var exp in todaysExpense){
                    tempSecMetric[exp.expenseType.name] = (tempSecMetric[exp.expenseType.name] ?? 0.0) + exp.price;
                }
                for (var entry in tempSecMetric.entries) {
                    Map<String, double> tempMetric = {};
                    tempMetric[entry.key] = entry.value;
                    secondaryMetric.add(tempMetric);
                }
                fullMetrics[primaryMetric] = secondaryMetric;
            }
            if (fullMetrics.isNotEmpty) {
                Map<String, double> primaryTempMetric = fullMetrics.keys.first;
                primaryTempMetric['Total'] = (primaryTempMetric['Total'] ?? 0.0) + overallTotal;
            }
        }

        return fullMetrics;


    }

}