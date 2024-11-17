import 'package:expense_log/models/expense.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/services/settings_service.dart';
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

    Map<String,double> getMetrics(String duration){
        final expenseTypes = getExpenseTypes();
        final expenses = getExpenses();
        Map<String, double> metricByType = {'Total': 0.0};
        DateTime now = DateTime.now();
        DateTime startDate = DateTime(now.year,now.month,now.day);

        switch(duration){
            case 'This week':
                startDate = startDate.subtract(Duration(days: now.weekday - 1));
                break;
            case 'Last week':
                startDate = startDate.subtract(Duration(days: now.weekday + 6 ));
                break;
            case 'This month':
                startDate = DateTime(now.year , now.month ,1);
                break;
            case 'Last month':
                startDate = DateTime(now.year , now.month - 1 ,1);
                break;
        }

        for(var expenseType in expenseTypes){
            double total = expenses.where((expense) => 
                expense.expenseType.id == expenseType.id &&
                expense.date.isAfter(startDate)
                ).fold(0.0,(sum,expense) => sum + expense.price);
            if(total != 0){
                metricByType[expenseType.name] = total;
                metricByType['Total'] = (metricByType['Total'] ?? 0.0) + total;
            }

        }
        return metricByType;
    }

}