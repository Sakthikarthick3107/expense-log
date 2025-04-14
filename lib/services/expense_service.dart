import 'package:expense_log/models/collection.dart';
import 'package:expense_log/models/expense.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/cloudsearch/v1.dart';
import 'package:hive/hive.dart';

class ExpenseService {
  final _expenseTypeBox = Hive.box<ExpenseType>('expenseTypeBox');
  final _expenseBox2 = Hive.box<Expense2>('expense2Box');
  final _collectionBox = Hive.box<Collection>('collectionBox');

  List<ExpenseType> getExpenseTypes() {
    List<ExpenseType> expenseTypes = List.from(_expenseTypeBox.values);
    expenseTypes.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return expenseTypes;
  }

  double getTypeLimitUsage(ExpenseType type){
    final today = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    if (type.limitBy == 'Week') {
      final weekday = today.weekday % 7;
      startDate = today.subtract(Duration(days: weekday));
      endDate = startDate.add(const Duration(days: 6));

      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    } else if (type.limitBy == 'Month') {
      startDate = DateTime(today.year, today.month, 1);
      endDate = DateTime(today.year, today.month + 1, 0);

      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    } else {
      return -1;
    }

    final total = getExpenses()
        .where((e) =>
    e.expenseType.id == type.id &&
        e.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
        e.date.isBefore(endDate.add(const Duration(days: 1))))
        .fold<double>(0.0, (sum, e) => sum + e.price);

    return total;
  }





  List<Expense2> getExpenses() => _expenseBox2.values.toList();

  bool ifExpenseTypeExist(ExpenseType type) {
    final expenseTypes = _expenseTypeBox.values.toList();
    return expenseTypes.any((expType) =>
    expType.name.toLowerCase() == type.name.toLowerCase());
  }

  int createExpenseType(ExpenseType type) {
    final checkIfExist = _expenseTypeBox.get(type.id);
    if (checkIfExist == null) {
      if (ifExpenseTypeExist(type)) {
        return 0;
      }
      else {
        _expenseTypeBox.put(type.id, type);
        return 1;
      }
    }
    else {
      if (type.name.toLowerCase() != checkIfExist.name.toLowerCase()) {
        if (ifExpenseTypeExist(type)) {
          return 0;
        }
      }
      final isLimitByChanged = checkIfExist.limitBy != type.limitBy;
      final isLimitChanged = checkIfExist.limit != type.limit;

      if (
      (isLimitByChanged || isLimitChanged) &&
          (type.limit != null || type.limitBy != null)
      ) {

        final today = DateTime.now();
        DateTime startDate;
        DateTime endDate;

        if (type.limitBy == 'Week') {
          final weekday = today.weekday % 7;
          startDate = today.subtract(Duration(days: weekday));
          endDate = startDate.add(const Duration(days: 6));

          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

        } else if (type.limitBy == 'Month') {
          startDate = DateTime(today.year, today.month, 1);
          endDate = DateTime(today.year, today.month + 1, 0);

          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        } else {
          return -1;
        }

        final total = getExpenses()
            .where((e) =>
        e.expenseType.id == type.id &&
            e.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(endDate.add(const Duration(days: 1))))
            .fold<double>(0.0, (sum, e) => sum + e.price);

        if (total > 0 && (checkIfExist.limitBy != null || checkIfExist.limit != null)) {
          return -1;
        }
      }
      else if((type.limit == null || type.limitBy == null)){
        final today = DateTime.now();
        DateTime startDate;
        DateTime endDate;

        if (checkIfExist.limitBy == 'Week') {
          final weekday = today.weekday % 7;
          startDate = today.subtract(Duration(days: weekday));
          endDate = startDate.add(const Duration(days: 6));

          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

        } else if (checkIfExist.limitBy == 'Month') {
          startDate = DateTime(today.year, today.month, 1);
          endDate = DateTime(today.year, today.month + 1, 0);

          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        } else {
          return -1;
        }

        final total = getExpenses()
            .where((e) =>
        e.expenseType.id == type.id &&
            e.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(endDate.add(const Duration(days: 1))))
            .fold<double>(0.0, (sum, e) => sum + e.price);

        if (total > 0) {
          return -1;
        }

      }
      _expenseTypeBox.put(type.id, type);
      _expenseBox2.values
          .where((expense) => expense.expenseType.id == type.id)
          .forEach((expense) =>
          _expenseBox2.put(expense.id, expense.copyWith(expenseType: type)));

      _collectionBox.values.forEach((collection) {
        collection.updateExpensesForType(type);
        _collectionBox.put(collection.id, collection);
      });
      return 1;
    }
  }

  int createExpense(Expense2 expense) {
    // if(isTypeLimitExceeded(expense)){
    //   return -1; // expense limit exceeds
    // }
    // else{
      _expenseBox2.put(expense.id, expense);
      return 1;
    // }

  }

  bool isTypeLimitExceeded(Expense2 expense){
    final limit = expense.expenseType.limit;
    final limitBy = expense.expenseType.limitBy;

    if (limit == null || limitBy == null) return false;

    final expenseDate = expense.date;

    final today = DateTime.now();

    DateTime startDate;
    DateTime endDate;

    if (limitBy == 'Week') {
      final weekday = today.weekday % 7;
      startDate = today.subtract(Duration(days: weekday));
      endDate = startDate.add(const Duration(days: 6));

      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    } else if (limitBy == 'Month') {
      startDate = DateTime(today.year, today.month, 1);
      endDate = DateTime(today.year, today.month + 1, 0);

      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    } else {
      return false;
    }

    if (expenseDate.isBefore(startDate) || expenseDate.isAfter(endDate)) {
      return false;
    }

    final matchingExpenses = getExpenses().where((e) =>
    e.id != expense.id &&
    e.expenseType.id == expense.expenseType.id &&
        e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        e.date.isBefore(endDate.add(const Duration(days: 1)))
    );

    final total = matchingExpenses.fold<double>(0.0, (sum, e) => sum + e.price);

    return total + expense.price > limit;
  }

  List<String>? exceededExpenses(List<Expense2> newExpenses) {
    final today = DateTime.now();
    final Map<int, double> typeTotals = {};
    final Map<int, ExpenseType> typeMap = {};

    for (var newExp in newExpenses) {
      final type = newExp.expenseType;
      final typeId = type.id;

      DateTime startDate;
      DateTime endDate;

      if (type.limitBy == 'Week') {
        final weekday = today.weekday % 7;
        startDate = today.subtract(Duration(days: weekday));
        endDate = startDate.add(const Duration(days: 6));
      } else if (type.limitBy == 'Month') {
        startDate = DateTime(today.year, today.month, 1);
        endDate = DateTime(today.year, today.month + 1, 0);
      } else {
        continue;
      }

      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      final previousTotal = getExpenses()
          .where((e) =>
      e.expenseType.id == typeId &&
          e.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(endDate.add(const Duration(seconds: 1))))
          .fold<double>(0, (sum, e) => sum + e.price);

      typeTotals[typeId] = (typeTotals[typeId] ?? previousTotal) + newExp.price;
      typeMap[typeId] = type;
    }

    final List<String> exceededList = [];
    typeTotals.forEach((typeId, totalAmount) {
      final type = typeMap[typeId]!;
      final limit = type.limit;

      if (limit != null && totalAmount > limit) {
        final exceededBy = (totalAmount - limit).toStringAsFixed(2);
        exceededList.add('${type.name} exceeded by ₹$exceededBy');
      }
    });
    return exceededList.isEmpty ? null : exceededList;
  }

  List<String> getExpenseTypeLimitSummary() {
    final today = DateTime.now();
    List<String> summaryList = [];
    List<ExpenseType> types = getExpenseTypes();

    for (final type in types) {
      if (type.limit == null || type.limitBy == null) continue;

      DateTime startDate;
      DateTime endDate;

      if (type.limitBy == 'Week') {
        final weekday = today.weekday % 7;
        startDate = today.subtract(Duration(days: weekday));
        endDate = startDate.add(const Duration(days: 6));
      } else if (type.limitBy == 'Month') {
        startDate = DateTime(today.year, today.month, 1);
        endDate = DateTime(today.year, today.month + 1, 0);
      } else {
        continue;
      }

      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      final totalSpent = getExpenses()
          .where((e) =>
      e.expenseType.id == type.id &&
          e.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(endDate.add(const Duration(days: 1))))
          .fold<double>(0.0, (sum, e) => sum + e.price);

      summaryList.add(
        '${type.name} - ${type.limitBy} (₹${totalSpent.toStringAsFixed(0)} / ₹${type.limit!.toStringAsFixed(0)})',
      );
    }

    return summaryList;
  }



  Future<int> createCollectionExpense(
      {required List<Expense2> expenses, required DateTime expenseDate}) async {
    try {
      SettingsService settingsService = SettingsService();
      int skipped = 0;
      for (Expense2 exp in expenses) {
        Expense2 newExpense = exp.copyWith(
            id: await settingsService.getBoxKey('expenseId'),
            date: expenseDate,
            created: DateTime.now(),
            updated: null,
        );
        if(isTypeLimitExceeded(newExpense)){
          skipped ++;
        }
        else{
          createExpense(newExpense);
        }
        }
      return skipped;
    }
    catch(e){
      print('Error $e');
      return -1;
    }
  }

  Future<int> copyAndSaveExpenses(
      {required DateTime copyFromDate, required DateTime pasteToDate , List<String>? exceedList}) async {
    try {
      // print(getExpenses());
      int skipped = 0;
      List<Expense2> getExpensesOfTheSelectedDate = getExpensesOfTheDay(
          copyFromDate);
      if (getExpensesOfTheSelectedDate.length == 0) {
        return -1;
      }
      if(exceedList !=  null){
        var exceedStatus = exceededExpenses(getExpensesOfTheSelectedDate);
        if (exceedStatus != null) {
          exceedList.addAll(exceedStatus);
        }
      }
      // print('Selected expenses: $getExpensesOfTheSelectedDate');
      SettingsService settingsService = SettingsService();

      for (Expense2 exp in getExpensesOfTheSelectedDate) {
        Expense2 newExpense = exp.copyWith(
          id: await settingsService.getBoxKey('expenseId'),
          date: pasteToDate,
          created: DateTime.now(),
          updated: null,
        );
        // if(isTypeLimitExceeded(newExpense)){
        //   skipped ++;
        // }
        // else{
          createExpense(newExpense);
        // }
      }

      return skipped;
    } catch (e) {
      print('Error copying expenses: $e');
      return -2;
    }
  }


  void deleteExpense(Map<int, Expense2> expenses) =>
      {
        expenses.forEach((id, expense) {
          _expenseBox2.delete(expense.id);
        })
      };

  List<Expense2> getExpensesOfTheDay(DateTime selectedDate) {
    return getExpenses().where((expense) {
      DateTime expDate = expense.date;
      return expDate.year == selectedDate.year &&
          expDate.month == selectedDate.month &&
          expDate.day == selectedDate.day;
    }).toList();
  }

  double selectedDayTotalExpense(DateTime selectedDate) {
    final expenseOfTheDate = getExpensesOfTheDay(selectedDate);
    return expenseOfTheDate.fold(
        0.0, (total, expense) => total + expense.price);
  }

  List<String> expenseTypesOfSelectedDuration(String duration,
      {DateTimeRange? customDateRange}) {
    final expenseTypes = getExpenseTypes();
    final expenses = getExpenses();
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day);
    DateTime endDate = now;
    List<String> usedTypes = [];
    switch (duration) {
      case 'This week':
        startDate = startDate.subtract(Duration(days: startDate.weekday % 7));
        endDate = startDate.add(Duration(days: 6));
        break;
      case 'Last week':
        startDate =
            startDate.subtract(Duration(days: (startDate.weekday + 7) % 7 + 7));
        endDate = startDate.add(Duration(days: 6));
        break;
      case 'This month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Last month':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0);
        break;
      default:
        startDate = customDateRange!.start;
        endDate = customDateRange.end;
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

  Map<String, double> getMetrics(String duration, String metricBy,
      List<String> unselectedTypes , {DateTimeRange? customDateRange}) {
    final expenseTypes = getExpenseTypes();
    final expenses = getExpenses();
    Map<String, double> metricData = {'Total': 0.0};
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day);
    DateTime endDate = now;

    switch (duration) {
      case 'This week':
        startDate = startDate.subtract(Duration(days: startDate.weekday % 7));
        endDate = startDate.add(Duration(days: 6));
        break;
      case 'Last week':
        startDate =
            startDate.subtract(Duration(days: (startDate.weekday + 7) % 7 + 7));
        endDate = startDate.add(Duration(days: 6));
        break;
      case 'This month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Last month':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0);
        break;
      default:
        startDate = customDateRange!.start;
        endDate = customDateRange.end;
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
      for (var expense in expenses.where((exp) =>
      !unselectedTypes.contains(exp.expenseType.name) &&
          !exp.date.isBefore(startDate) &&
          exp.date.isBefore(endDate.add(Duration(days: 1))))) {
        DateTime day = DateTime(
            expense.date.year, expense.date.month, expense.date.day);
        tempMetricsData[day] = (tempMetricsData[day] ?? 0.0) + expense.price;
        overallTotal += expense.price;
      }
      List<DateTime> sortedDays = tempMetricsData.keys.toList();
      sortedDays.sort((a, b) => b.compareTo(a));
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

  Map<Map<String, double>, List<Map<String, double>>> getMetrics2(
      String duration, String metricBy, List<String> unselectedTypes,
      {DateTimeRange? customDateRange}) {
    final expenseTypes = getExpenseTypes();
    final expenses = getExpenses();
    UiService uiService = UiService();
    Map<Map<String, double>, List<Map<String, double>>> fullMetrics = {};
    fullMetrics[{'Total': 0.0}] = [];
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day);
    DateTime endDate = now;

    switch (duration) {
      case 'This week':
        startDate = startDate.subtract(Duration(days: startDate.weekday % 7));
        endDate = startDate.add(Duration(days: 6));
        break;
      case 'Last week':
        startDate =
            startDate.subtract(Duration(days: (startDate.weekday + 7) % 7 + 7));
        endDate = startDate.add(Duration(days: 6));
        break;
      case 'This month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Last month':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0);
        break;
      default:
        startDate = customDateRange!.start;
        endDate = customDateRange.end;
        break;
    }

    // print('Start Date ${startDate}');

    if (metricBy == 'By type') {
      for (var expenseType in expenseTypes) {
        var filterWithType = expenses.where((expense) =>
        expense.expenseType.id == expenseType.id &&
            !expense.date.isBefore(startDate) &&
            expense.date.isBefore(endDate.add(Duration(days: 1))) &&
            !unselectedTypes.contains(expenseType.name)
        );

        double total = filterWithType.fold(
            0.0, (sum, expense) => sum + expense.price);

        if (total != 0) {
          Map<String, double> primaryMetric = {};

          primaryMetric[expenseType.name] = total;

          List<Map<String, double>> secondaryMetric = [];
          Map<DateTime, double> secondaryTempMetric = {};
          for (var expenseDate in filterWithType) {
            DateTime day = DateTime(
                expenseDate.date.year, expenseDate.date.month,
                expenseDate.date.day);
            secondaryTempMetric[day] =
                (secondaryTempMetric[day] ?? 0) + expenseDate.price;
          }

          List<DateTime> sortedDays = secondaryTempMetric.keys.toList();
          sortedDays.sort((a, b) => b.compareTo(a));
          for (DateTime day in sortedDays) {
            String dayString = uiService.displayDay(day);
            double dailyTotal = secondaryTempMetric[day]!;
            secondaryMetric.add({dayString: dailyTotal});
          }
          fullMetrics[primaryMetric] = secondaryMetric;
          if (fullMetrics.isNotEmpty) {
            Map<String, double> primaryTempMetric = fullMetrics.keys.first;
            primaryTempMetric['Total'] =
                (primaryTempMetric['Total'] ?? 0.0) + total;
          }
        }
      }
    }

    else if (metricBy == 'By day') {
      Map<DateTime, double> primaryTempMetricsData = {};
      double overallTotal = 0.0;

      var filterWithDayLimit = expenses.where((exp) =>
      !unselectedTypes.contains(exp.expenseType.name) &&
          !exp.date.isBefore(startDate) &&
          exp.date.isBefore(endDate.add(Duration(days: 1))));

      for (var expense in filterWithDayLimit) {
        DateTime day = DateTime(
            expense.date.year, expense.date.month, expense.date.day);
        primaryTempMetricsData[day] =
            (primaryTempMetricsData[day] ?? 0.0) + expense.price;
        overallTotal += expense.price;
      }
      List<DateTime> sortedDays = primaryTempMetricsData.keys.toList();
      sortedDays.sort((a, b) => b.compareTo(a));
      Map<String, double> sortedMetricsData = {'Total': overallTotal};


      for (DateTime day in sortedDays) {
        Map<String, double> primaryMetric = {};
        List<Map<String, double>> secondaryMetric = [];

        String dayString = uiService.displayDay(day);
        double dailyTotal = primaryTempMetricsData[day]!;
        primaryMetric[dayString] = dailyTotal;

        var todaysExpense = filterWithDayLimit.where((selected) =>
        day.year == selected.date.year &&
            day.month == selected.date.month &&
            day.day == selected.date.day
        );
        Map<String, double> tempSecMetric = {};

        for (var exp in todaysExpense) {
          tempSecMetric[exp.expenseType.name] =
              (tempSecMetric[exp.expenseType.name] ?? 0.0) + exp.price;
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
        primaryTempMetric['Total'] =
            (primaryTempMetric['Total'] ?? 0.0) + overallTotal;
      }
    }

    return fullMetrics;
  }

}