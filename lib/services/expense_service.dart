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

    Map<String,double> getMetrics(String duration , String metricBy){
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
            // setup
            for (var expenseType in expenseTypes) {
                double total = expenses.where((expense) =>
                expense.expenseType.id == expenseType.id &&
                    !expense.date.isBefore(startDate) &&  // Include start date
                    expense.date.isBefore(endDate.add(Duration(days: 1)))) // Include end date
                    .fold(0.0, (sum, expense) => sum + expense.price);

                if (total != 0) {
                    metricData[expenseType.name] = total;
                    metricData['Total'] = (metricData['Total'] ?? 0.0) + total;
                }
            }
        }

        else if (metricBy == 'By day') {
            UiService uiService = UiService();

            // Temporary map to store total for each day, and a variable to accumulate the overall total.
            Map<DateTime, double> tempMetricsData = {};
            double overallTotal = 0.0; // Track the overall total separately

            // Loop through all expenses that match the date range (startDate to endDate)
            for (var expense in expenses.where((exp) => exp.date.isAfter(startDate) && exp.date.isBefore(endDate.add(Duration(days: 1))))) {
                DateTime day = expense.date;

                // Accumulate the expense price for each day
                tempMetricsData[day] = (tempMetricsData[day] ?? 0.0) + expense.price;

                // Accumulate the total for the entire period
                overallTotal += expense.price;
            }

            // Debug: Print tempMetricsData before sorting
            print("Temp Metrics Data (Before Sorting): $tempMetricsData");

            // Sort the days in ascending order
            List<DateTime> sortedDays = tempMetricsData.keys.toList();
            sortedDays.sort();

            // Map to store the final sorted metrics with the 'Total' key
            Map<String, double> sortedMetricsData = {'Total': overallTotal};

            // Debug: Print sorted days
            print("Sorted Days: $sortedDays");

            // Loop through the sorted days and update the metrics data for each day
            for (DateTime day in sortedDays) {
                String dayString = uiService.displayDay(day);
                double dailyTotal = tempMetricsData[day]!;

                // Add the daily total to the sorted metrics data
                sortedMetricsData[dayString] = dailyTotal;
            }

            // Debug: Print sorted metrics data
            print("Sorted Metrics Data (After Processing): $sortedMetricsData");

            // Set the final metric data
            metricData = sortedMetricsData;
        }

        return metricData;


    }

}