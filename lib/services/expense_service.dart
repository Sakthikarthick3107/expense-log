import 'package:expense_log/models/collection.dart';
import 'package:expense_log/models/date_range.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/services/audit_log_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ExpenseService {
  final UiService uiService;
  final _expenseTypeBox = Hive.box<ExpenseType>('expenseTypeBox');
  final _expenseBox2 = Hive.box<Expense2>('expense2Box');
  final _collectionBox = Hive.box<Collection>('collectionBox');

  ExpenseService({required this.uiService});

  List<ExpenseType> getExpenseTypes() {
    List<ExpenseType> expenseTypes = List.from(_expenseTypeBox.values);
    expenseTypes
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return expenseTypes;
  }

  double getTypeLimitUsage(ExpenseType type) {
    DateTime startDate;
    DateTime endDate;
    DateRange? getRange = uiService.getDateRange(type.limitBy ?? '');
    if (getRange != null) {
      startDate = getRange.start;
      endDate = getRange.end;
    } else
      return -1;

    final total = getExpenses()
        .where((e) =>
            e.expenseType.id == type.id &&
            e.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(endDate.add(const Duration(days: 1))))
        .fold<double>(0.0, (sum, e) => sum + e.price);

    return total;
  }

  List<Expense2> getExpenses() => _expenseBox2.values.toList();

  List<Expense2> getExpensesOfSelectedDuration(String rangeType,
      {DateTimeRange? customDateRange}) {
    DateTime startDate;
    DateTime endDate;

    DateRange? getRange = uiService.getDateRange(rangeType);

    if (getRange != null) {
      startDate = getRange.start;
      endDate = getRange.end;
    } else if (customDateRange != null) {
      startDate = customDateRange.start;
      endDate = customDateRange.end;
    } else {
      throw Exception('No valid date range provided.');
    }

    List<Expense2> filteredExpenses = getExpenses().where((expense) {
      return expense.date.isAfter(startDate.subtract(Duration(days: 1))) &&
          expense.date.isBefore(endDate.add(Duration(days: 1)));
    }).toList();

    return filteredExpenses;
  }

  bool ifExpenseTypeExist(ExpenseType type) {
    final expenseTypes = _expenseTypeBox.values.toList();
    return expenseTypes.any(
        (expType) => expType.name.toLowerCase() == type.name.toLowerCase());
  }

  int createExpenseType(ExpenseType type) {
    final checkIfExist = _expenseTypeBox.get(type.id);
    if (checkIfExist == null) {
      if (ifExpenseTypeExist(type)) {
        return 0;
      } else {
        _expenseTypeBox.put(type.id, type);
        AuditLogService.writeLog(
            'Created/edited type - ${type.name} ${type.limit! > 0 ? 'with limit of ${type.limit}/${type.limitBy}' : ' without limit set '}');

        return 1;
      }
    } else {
      if (type.name.toLowerCase() != checkIfExist.name.toLowerCase()) {
        if (ifExpenseTypeExist(type)) {
          return 0;
        }
      }
      final isLimitByChanged = checkIfExist.limitBy != type.limitBy;
      final isLimitChanged = checkIfExist.limit != type.limit;

      if ((isLimitChanged) && (type.limit != null || type.limitBy != null)) {
        DateTime startDate;
        DateTime endDate;

        DateRange? getRange = uiService.getDateRange(type.limitBy ?? '');
        if (getRange != null) {
          startDate = getRange.start;
          endDate = getRange.end;
        } else
          return -1;

        final total = getExpenses()
            .where((e) =>
                e.expenseType.id == type.id &&
                e.date
                    .isAfter(startDate.subtract(const Duration(seconds: 1))) &&
                e.date.isBefore(endDate.add(const Duration(days: 1))))
            .fold<double>(0.0, (sum, e) => sum + e.price);

        if (total > 0 &&
            (checkIfExist.limitBy != null || checkIfExist.limit != null)) {
          return -1;
        }
      }
      if ((isLimitByChanged || (type.limit == null || type.limitBy == null)) &&
          (checkIfExist.limit != null || checkIfExist.limitBy != null)) {
        DateTime startDate;
        DateTime endDate;

        DateRange? getRange = uiService.getDateRange(type.limitBy ?? '');
        if (getRange != null) {
          startDate = getRange.start;
          endDate = getRange.end;
        } else
          return -1;

        final total = getExpenses()
            .where((e) =>
                e.expenseType.id == type.id &&
                e.date
                    .isAfter(startDate.subtract(const Duration(seconds: 1))) &&
                e.date.isBefore(endDate.add(const Duration(days: 1))))
            .fold<double>(0.0, (sum, e) => sum + e.price);

        if (total > 0) {
          return -1;
        }
      }
      AuditLogService.writeLog(
          'Created/edited type - ${type.name} ${type.limit! > 0 ? 'with limit of ${type.limit}/${type.limitBy}' : ' without limit set '}');
      _expenseTypeBox.put(type.id, type);
      _expenseBox2.values
          .where((expense) => expense.expenseType.id == type.id)
          .forEach((expense) => _expenseBox2.put(
              expense.id, expense.copyWith(expenseType: type)));

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
    AuditLogService.writeLog(
        'Created/edited expense - ${expense.name} ₹${expense.price} ${expense.expenseType.name} for day ${expense.date.day}-${expense.date.month}-${expense.date.year}');

    return 1;
    // }
  }

  bool isTypeLimitExceeded(Expense2 expense) {
    final limit = expense.expenseType.limit;
    final limitBy = expense.expenseType.limitBy;

    if (limit == null || limitBy == null) return false;

    final expenseDate = expense.date;

    DateTime startDate;
    DateTime endDate;

    DateRange? getRange = uiService.getDateRange(limitBy);
    if (getRange != null) {
      startDate = getRange.start;
      endDate = getRange.end;
    } else
      return false;

    if (expenseDate.isBefore(startDate) || expenseDate.isAfter(endDate)) {
      return false;
    }

    final matchingExpenses = getExpenses().where((e) =>
        e.id != expense.id &&
        e.expenseType.id == expense.expenseType.id &&
        e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        e.date.isBefore(endDate.add(const Duration(days: 1))));

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

      DateRange? getRange = uiService.getDateRange(type.limitBy ?? '');
      if (getRange != null) {
        startDate = getRange.start;
        endDate = getRange.end;
      } else
        continue;

      final previousTotal = getExpenses()
          .where((e) =>
              e.expenseType.id == typeId &&
              e.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              e.date.isBefore(endDate.add(const Duration(seconds: 1))))
          .fold<double>(0, (sum, e) => sum + e.price);

      if (newExp.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          newExp.date.isBefore(endDate.add(const Duration(seconds: 1)))) {
        typeTotals[typeId] =
            (typeTotals[typeId] ?? previousTotal) + newExp.price;
        typeMap[typeId] = type;
      }
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
    if(exceededList.isNotEmpty){
         AuditLogService.writeLog('Type Limit exceeds - ${exceededList.join(',')} ');
    }
    return exceededList.isEmpty ? null : exceededList;
  }

  List<String> getExpenseTypeLimitSummary() {
    List<String> summaryList = [];
    List<ExpenseType> types = getExpenseTypes();

    for (final type in types) {
      if (type.limit == null || type.limitBy == null) continue;

      DateTime startDate;
      DateTime endDate;

      DateRange? getRange = uiService.getDateRange(type.limitBy!);
      if (getRange != null) {
        startDate = getRange.start;
        endDate = getRange.end;
      } else
        continue;

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

  List<Expense2> getExpenseForType(ExpenseType? type) {
    var expenses =
        getExpenses().where((exp) => exp.expenseType.id == type?.id).toList();
    return expenses;
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
        if (isTypeLimitExceeded(newExpense)) {
          skipped++;
        } else {
          createExpense(newExpense);
        }
      }
      return skipped;
    } catch (e) {
      print('Error $e');
      return -1;
    }
  }

  Future<int> copyAndSaveExpenses(
      {required DateTime copyFromDate,
      required DateTime pasteToDate,
      List<String>? exceedList}) async {
    try {
      // print(getExpenses());
      int skipped = 0;
      List<Expense2> getExpensesOfTheSelectedDate =
          getExpensesOfTheDay(copyFromDate);
      if (getExpensesOfTheSelectedDate.length == 0) {
        return -1;
      }
      if (exceedList != null) {
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
      AuditLogService.writeLog(
          'Copied all expenses from ${copyFromDate.day}-${copyFromDate.month}-${copyFromDate.year} to ${pasteToDate.day}-${pasteToDate.month}-${pasteToDate.year}');
      return skipped;
    } catch (e) {
      print('Error copying expenses: $e');
      return -2;
    }
  }

  void deleteExpense(Map<int, Expense2> expenses) {
    DateTime expenseDay = expenses.entries.first.value.date;
    expenses.forEach((id, expense) {
      _expenseBox2.delete(expense.id);
    });
    AuditLogService.writeLog(
        'Deleted ${expenses.length} expenses of ${expenseDay.day}-${expenseDay.month}-${expenseDay.year}');
  }

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

    DateTime startDate;
    DateTime endDate;
    List<String> usedTypes = [];
    DateRange? getRange =
        uiService.getDateRange(duration, customDateRange: customDateRange);

    startDate = getRange!.start;
    endDate = getRange!.end;

    for (var expenseType in expenseTypes) {
      double total = expenses
          .where((expense) =>
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

  Map<String, double> getMetrics(
      String duration, String metricBy, List<String> unselectedTypes,
      {DateTimeRange? customDateRange}) {
    final expenseTypes = getExpenseTypes();
    final expenses = getExpenses();
    Map<String, double> metricData = {'Total': 0.0};

    DateTime startDate;
    DateTime endDate;
    DateRange? getRange =
        uiService.getDateRange(duration, customDateRange: customDateRange);

    startDate = getRange!.start;
    endDate = getRange.end;

    if (metricBy == 'By type') {
      for (var expenseType in expenseTypes) {
        double total = expenses
            .where((expense) =>
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
    } else if (metricBy == 'By day') {
      UiService uiService = UiService();
      Map<DateTime, double> tempMetricsData = {};
      double overallTotal = 0.0;
      for (var expense in expenses.where((exp) =>
          !unselectedTypes.contains(exp.expenseType.name) &&
          !exp.date.isBefore(startDate) &&
          exp.date.isBefore(endDate.add(Duration(days: 1))))) {
        DateTime day =
            DateTime(expense.date.year, expense.date.month, expense.date.day);
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

    DateTime startDate;
    DateTime endDate;

    DateRange? getRange =
        uiService.getDateRange(duration, customDateRange: customDateRange);

    startDate = getRange!.start;
    endDate = getRange.end;

    if (metricBy == 'By type') {
      for (var expenseType in expenseTypes) {
        var filterWithType = expenses.where((expense) =>
            expense.expenseType.id == expenseType.id &&
            !expense.date.isBefore(startDate) &&
            expense.date.isBefore(endDate.add(Duration(days: 1))) &&
            !unselectedTypes.contains(expenseType.name));

        double total =
            filterWithType.fold(0.0, (sum, expense) => sum + expense.price);

        if (total != 0) {
          Map<String, double> primaryMetric = {};

          primaryMetric[expenseType.name] = total;

          List<Map<String, double>> secondaryMetric = [];
          Map<DateTime, double> secondaryTempMetric = {};
          for (var expenseDate in filterWithType) {
            DateTime day = DateTime(expenseDate.date.year,
                expenseDate.date.month, expenseDate.date.day);
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
    } else if (metricBy == 'By day') {
      Map<DateTime, double> primaryTempMetricsData = {};
      double overallTotal = 0.0;

      var filterWithDayLimit = expenses.where((exp) =>
          !unselectedTypes.contains(exp.expenseType.name) &&
          !exp.date.isBefore(startDate) &&
          exp.date.isBefore(endDate.add(Duration(days: 1))));

      for (var expense in filterWithDayLimit) {
        DateTime day =
            DateTime(expense.date.year, expense.date.month, expense.date.day);
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
            day.day == selected.date.day);
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
