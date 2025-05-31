import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/report_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/widgets/calendar_chart_widget.dart';
import 'package:expense_log/widgets/expense_bar_chart.dart';
import 'package:expense_log/widgets/expense_pie_chart.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:expense_log/widgets/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  late ExpenseService _expenseService;
  late UiService _uiService;
  late SettingsService _settingsService;
  late ReportService _reportService;
  final List<String> metricsDuration = [
    'This week',
    'Last week',
    'This month',
    'Last month',
    'Custom'
  ];
  final List<String> metricsBy = ['By type', 'By day'];
  final ValueNotifier<String> _selectedDurationNotifier =
      ValueNotifier<String>('This week');
  final ValueNotifier<String> _selectedMetricBy =
      ValueNotifier<String>('By type');
  late Map<String, double> _metricsData = {};
  late Map<String, double> _barCharData = {};
  late Map<DateTime, double> _calendarChartData = {};
  DateTimeRange? selectedDateRange;
  late List<String> _expenseTypesOfDuration;
  late List<String> _unSelectedTypes = [];
  late Map<Map<String, double>, List<Map<String, double>>> _metricsData2 = {};

  String? _selectedKey;

  @override
  void initState() {
    super.initState();
    _expenseService = Provider.of<ExpenseService>(context, listen: false);
    _uiService = Provider.of<UiService>(context, listen: false);
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _reportService = Provider.of<ReportService>(context, listen: false);
    _selectedDurationNotifier.value = _settingsService.landingMetric();
    _expenseTypesOfDuration = _expenseService.expenseTypesOfSelectedDuration(
        _selectedDurationNotifier.value,
        customDateRange: selectedDateRange);
    _metricsData = _expenseService.getMetrics(_selectedDurationNotifier.value,
        _selectedMetricBy.value, _unSelectedTypes,
        customDateRange: selectedDateRange);
    _metricsData2 = _expenseService.getMetrics2(_selectedDurationNotifier.value,
        _selectedMetricBy.value, _unSelectedTypes,
        customDateRange: selectedDateRange);
    _barCharData = _expenseService.getMetrics(
        _selectedDurationNotifier.value, 'By type', _unSelectedTypes,
        customDateRange: selectedDateRange);
    _calendarChartData = _expenseService.getMetrics<DateTime>(
        _selectedDurationNotifier.value, 'By day', _unSelectedTypes,
        customDateRange: selectedDateRange);
    _selectedDurationNotifier.addListener(() {
      _expenseTypesOfDuration = _expenseService.expenseTypesOfSelectedDuration(
          _selectedDurationNotifier.value,
          customDateRange: selectedDateRange);
      _metricsData = _expenseService.getMetrics(_selectedDurationNotifier.value,
          _selectedMetricBy.value, _unSelectedTypes,
          customDateRange: selectedDateRange);
      _metricsData2 = _expenseService.getMetrics2(
          _selectedDurationNotifier.value,
          _selectedMetricBy.value,
          _unSelectedTypes,
          customDateRange: selectedDateRange);
      _barCharData = _expenseService.getMetrics(
          _selectedDurationNotifier.value, 'By type', _unSelectedTypes,
          customDateRange: selectedDateRange);
      _calendarChartData = _expenseService.getMetrics(
          _selectedDurationNotifier.value, 'By day', _unSelectedTypes,
          customDateRange: selectedDateRange);
    });
    _selectedMetricBy.addListener(() {
      _metricsData = _expenseService.getMetrics(_selectedDurationNotifier.value,
          _selectedMetricBy.value, _unSelectedTypes,
          customDateRange: selectedDateRange);
      _metricsData2 = _expenseService.getMetrics2(
          _selectedDurationNotifier.value,
          _selectedMetricBy.value,
          _unSelectedTypes,
          customDateRange: selectedDateRange);
      _barCharData = _expenseService.getMetrics(
          _selectedDurationNotifier.value, 'By type', _unSelectedTypes,
          customDateRange: selectedDateRange);
      _calendarChartData = _expenseService.getMetrics(
          _selectedDurationNotifier.value, 'By day', _unSelectedTypes,
          customDateRange: selectedDateRange);
    });
  }

  void _showMultiSelectDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return AlertDialog(
            shape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            title: Text("Select/Unselect"),
            content: SingleChildScrollView(
              child: ListBody(
                children: _expenseTypesOfDuration.map((item) {
                  bool isUnchecked = !_unSelectedTypes.contains(item);
                  return CheckboxListTile(
                    title: Text(item),
                    value: isUnchecked,
                    onChanged: (isChecked) {
                      setStateDialog(() {
                        if (isChecked == true) {
                          _unSelectedTypes.remove(item);
                        } else {
                          _unSelectedTypes.add(item);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _metricsData = _expenseService.getMetrics(
                        _selectedDurationNotifier.value,
                        _selectedMetricBy.value,
                        _unSelectedTypes,
                        customDateRange: selectedDateRange);
                    _metricsData2 = _expenseService.getMetrics2(
                        _selectedDurationNotifier.value,
                        _selectedMetricBy.value,
                        _unSelectedTypes,
                        customDateRange: selectedDateRange);
                    _barCharData = _expenseService.getMetrics(
                        _selectedDurationNotifier.value,
                        'By type',
                        _unSelectedTypes,
                        customDateRange: selectedDateRange);
                    _calendarChartData = _expenseService.getMetrics(
                        _selectedDurationNotifier.value,
                        'By day',
                        _unSelectedTypes,
                        customDateRange: selectedDateRange);
                  });
                },
                child: Text("OK"),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body:
          Consumer<SettingsService>(builder: (context, settingsService, child) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            Container(
              child: Row(
                children: [
                  if (_metricsData2.keys
                      .where((metric) => metric.keys.first != 'Total')
                      .isNotEmpty)
                    IconButton(
                      onPressed: () {},
                      color: Theme.of(context).scaffoldBackgroundColor,
                      icon: const Icon(Icons.print),
                    ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        '₹ ${_metricsData2.keys.first['Total']?.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (_metricsData2.keys
                      .where((metric) => metric.keys.first != 'Total')
                      .isNotEmpty)
                    IconButton(
                      onPressed: () async {
                        WarningDialog.showWarning(
                            context: context,
                            title:
                                'Metrics Report - ${_selectedDurationNotifier.value}',
                            message: 'Proceed to download report ' +
                                '\n' +
                                'Selected Types : ' +
                                '\n - ' +
                                _expenseTypesOfDuration
                                    .where((type) =>
                                        !_unSelectedTypes.contains(type))
                                    .join('\n - ') +
                                '\n' +
                                'View : ${_selectedMetricBy.value}',
                            onConfirmed: () async {
                              MessageWidget.showToast(
                                  context: context,
                                  message: 'Downloading in progress...');
                              await _reportService.prepareMetricsReport(
                                  _expenseService.getExpensesOfSelectedDuration(
                                      _selectedDurationNotifier.value,
                                      customDateRange: selectedDateRange),
                                  _expenseTypesOfDuration
                                      .where((type) =>
                                          !_unSelectedTypes.contains(type))
                                      .toList(),
                                  _selectedMetricBy.value,
                                  _expenseService.uiService.getDateRange(
                                      _selectedDurationNotifier.value!,
                                      customDateRange: selectedDateRange)!);
                            });
                      },
                      icon: const Icon(Icons.print),
                    ),
                ],
              ),
            ),
            Expanded(
                child: ValueListenableBuilder(
                    valueListenable:
                        Hive.box<Expense2>('expense2Box').listenable(),
                    builder: (context, Box<Expense2> box, _) {
                      return ValueListenableBuilder(
                          valueListenable:
                              Hive.box<ExpenseType>('expenseTypeBox')
                                  .listenable(),
                          builder: (context, Box<ExpenseType> expenseBox, _) {
                            final primaryMetric = _metricsData2.keys;
                            if (primaryMetric
                                .where((metric) => metric.keys.first != 'Total')
                                .isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset('assets/amongus.png',
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover),
                                    const Text(
                                      'No metrics for the selected filters',
                                      style: TextStyle(fontSize: 20),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView(children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                child: SizedBox(
                                  height: 300,
                                  // child: ,
                                  child: settingsService.getMetricChart() ==
                                          'Bar Chart'
                                      ? ExpenseBarChart(
                                          expenseData: Map.from(_barCharData)
                                            ..remove('Total'))
                                      : settingsService.getMetricChart() ==
                                              'Pie Chart'
                                          ? SingleChildScrollView(
                                              child: ExpensePieChart(
                                                  expenseData:
                                                      Map.from(_barCharData)
                                                        ..remove('Total')))
                                          : Container(
                                              height: 200,
                                              child: SingleChildScrollView(
                                                child: CalendarChartWidget(
                                                  dayAmountMap:
                                                      _calendarChartData,
                                                  durationType:
                                                      _selectedDurationNotifier
                                                          .value, // e.g. 'This week', 'Month', 'Custom', etc.
                                                  customDateRange:
                                                      selectedDateRange,
                                                ),
                                              ),
                                            ),
                                ),
                              ),
                              ...primaryMetric
                                  .where(
                                      (metric) => metric.keys.first != 'Total')
                                  .map((metric) {
                                final key = metric.keys.first;
                                final value = metric[key] ?? 0.0;
                                final secondaryMetrics = _metricsData2[metric];
                                return Column(children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: 8),
                                    child: Material(
                                      elevation: settingsService.getElevation()
                                          ? (_selectedKey == key ? 4 : 2)
                                          : 0,
                                      borderRadius: BorderRadius.circular(10),
                                      color: Theme.of(context).cardColor,
                                      child: ListTile(
                                        onTap: () {
                                          setState(() {
                                            _selectedKey = _selectedKey == key
                                                ? null
                                                : key;
                                          });
                                        },

                                        title: Text(
                                          key,
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: _selectedKey == key
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: _selectedKey == key
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                  : Theme.of(context)
                                                      .textTheme
                                                      .displayMedium
                                                      ?.color),
                                        ),
                                        trailing: Text(
                                          '₹${value.toStringAsFixed(2)}',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: _selectedKey == key
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: _selectedKey == key
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                  : Theme.of(context)
                                                      .textTheme
                                                      .displayMedium
                                                      ?.color),
                                        ),
                                        // tileColor: _selectedKey == key ? Theme.of(context).primaryColor : Theme.of(context).listTileTheme.tileColor ,
                                      ),
                                    ),
                                  ),
                                  AnimatedSize(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      child: _selectedKey == key &&
                                              secondaryMetrics != null
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 30),
                                              child: Column(
                                                children: secondaryMetrics
                                                    .map((secondary) {
                                                  final secondaryMetricName =
                                                      secondary.keys.first;
                                                  final secondaryMetricValue =
                                                      secondary[
                                                              secondaryMetricName] ??
                                                          0.0;
                                                  return Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        secondaryMetricName,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      ),
                                                      Text(
                                                        '₹${secondaryMetricValue.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      )
                                                    ],
                                                  );
                                                }).toList(),
                                              ),
                                            )
                                          : SizedBox.shrink()),
                                ]);
                              }).toList(),
                            ]);
                          });
                    }))
          ]),
        );
      }),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: Theme.of(context).appBarTheme.backgroundColor,
        child: SizedBox(
          height: 80,
          child: Column(
            children: [
              if (selectedDateRange != null)
                Text(
                  '${_uiService.displayDay(selectedDateRange!.start)} - ${_uiService.displayDay(selectedDateRange!.end)}',
                ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                DropdownButton<String>(
                  value: _selectedMetricBy.value,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedMetricBy.value = newValue!;
                    });
                  },
                  items: metricsBy.map((String value) {
                    return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(fontSize: 16)));
                  }).toList(),
                ),
                DropdownButton<String>(
                  value: _selectedDurationNotifier.value,
                  onChanged: (String? newValue) async {
                    if (newValue == 'Custom') {
                      DateTimeRange? getRange =
                          await _uiService.selectedDuration(context,
                              lastSelectedRange: selectedDateRange);
                      if (getRange != selectedDateRange && getRange != null) {
                        setState(() {
                          selectedDateRange = getRange;

                          _selectedDurationNotifier.value = '';
                          _selectedDurationNotifier.value = 'Custom';
                        });
                      }
                    } else if (newValue != 'Custom') {
                      setState(() {
                        selectedDateRange = null;
                        _selectedDurationNotifier.value = newValue!;
                      });
                    }
                  },
                  items: metricsDuration.map((String value) {
                    return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(fontSize: 16),
                        ));
                  }).toList(),
                ),
                TextButton(
                  onPressed: () {
                    _showMultiSelectDialog(context);
                  },
                  child: Text('Filter Types'),
                )
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
