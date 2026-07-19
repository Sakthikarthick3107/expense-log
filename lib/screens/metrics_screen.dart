import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/group_service.dart';
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

class _MetricsScreenState extends State<MetricsScreen>
    with SingleTickerProviderStateMixin {
  late ExpenseService _expenseService;
  late UiService _uiService;
  late SettingsService _settingsService;
  late ReportService _reportService;
  late GroupService _groupService;
  late TabController _tabController;

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
  late Map<String, double> _barCharData = {};
  late Map<DateTime, double> _calendarChartData = {};
  DateTimeRange? selectedDateRange;
  late List<String> _expenseTypesOfDuration;
  late List<String> _unSelectedTypes = [];
  late Map<Map<String, double>, List<Map<String, double>>> _metricsData2 = {};

  String? _selectedKey;
  bool isDebit = true;

  int? _selectedGroupId;
  String? _selectedUserName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _expenseService = Provider.of<ExpenseService>(context, listen: false);
    _uiService = Provider.of<UiService>(context, listen: false);
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _reportService = Provider.of<ReportService>(context, listen: false);
    _groupService = Provider.of<GroupService>(context, listen: false);
    _selectedDurationNotifier.value = _settingsService.landingMetric();
    _loadMetrics();
    _selectedDurationNotifier.addListener(_loadMetrics);
    _selectedMetricBy.addListener(_loadMetrics);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        final groups = _groupService.getGroups();
        _selectedGroupId =
            _tabController.index == 1 && groups.isNotEmpty ? groups.first.id : null;
        _selectedUserName = null;
        _unSelectedTypes = [];
      });
      _loadMetrics();
    }
  }

  void _loadMetrics() {
    final isIndividual = _tabController.index == 0;
    final individualOnly = isIndividual && _selectedGroupId == null;
    final mappedUser = _tabController.index == 1 ? _selectedUserName : null;
    _expenseTypesOfDuration = _expenseService.expenseTypesOfSelectedDuration(
        _selectedDurationNotifier.value,
        customDateRange: selectedDateRange,
        groupId: _selectedGroupId,
        individualOnly: individualOnly,
        mappedUserName: mappedUser);
    _metricsData2 = _expenseService.getMetrics2(
        _selectedDurationNotifier.value,
        _selectedMetricBy.value,
        _unSelectedTypes,
        isDebit,
        customDateRange: selectedDateRange,
        groupId: _selectedGroupId,
        individualOnly: individualOnly,
        mappedUserName: mappedUser);
    _barCharData = _expenseService.getMetrics(
        _selectedDurationNotifier.value, 'By type', _unSelectedTypes,
        isDebit: isDebit,
        customDateRange: selectedDateRange,
        groupId: _selectedGroupId,
        individualOnly: individualOnly,
        mappedUserName: mappedUser);
    _calendarChartData = _expenseService.getMetrics<DateTime>(
        _selectedDurationNotifier.value, 'By day', _unSelectedTypes,
        isDebit: isDebit,
        customDateRange: selectedDateRange,
        groupId: _selectedGroupId,
        individualOnly: individualOnly,
        mappedUserName: mappedUser);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _selectedDurationNotifier.dispose();
    _selectedMetricBy.dispose();
    super.dispose();
  }

  void _showMultiSelectDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: Row(children: [
              Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary, size: 24),
              const SizedBox(width: 10),
              const Expanded(child: Text('Filter Types')),
            ]),
            content: SingleChildScrollView(
              child: ListBody(
                children: _expenseTypesOfDuration.map((item) {
                  bool isUnchecked = !_unSelectedTypes.contains(item);
                  return CheckboxListTile(
                    title: Text(item),
                    value: isUnchecked,
                    dense: true,
                    activeColor: Theme.of(context).colorScheme.primary,
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
                  _loadMetrics();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildMetricsContent() {
    if (_tabController.index == 1) {
      final groups = _groupService.getGroups();
      if (groups.isEmpty) {
        return const Center(
          child: Text('No groups created yet',
              style: TextStyle(fontSize: 16)),
        );
      }
    }
    return Column(children: [
      if (_tabController.index == 1) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonFormField<int>(
            value: _selectedGroupId,
            isExpanded: true,
            hint: const Text('Select Group'),
            items: _groupService.getGroups().map((g) {
              return DropdownMenuItem(
                value: g.id,
                child: Text(g.name),
              );
            }).toList(),
            onChanged: (v) {
              setState(() {
                _selectedGroupId = v;
                _selectedUserName = null;
                _unSelectedTypes = [];
              });
              _loadMetrics();
            },
            decoration: const InputDecoration(
              labelText: 'Group',
              prefixIcon: Icon(Icons.groups, size: 20),
            ),
          ),
        ),
        if (_selectedGroupId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonFormField<String>(
              value: _selectedUserName,
              isExpanded: true,
              hint: const Text('All Users'),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('All Users')),
                ...(_groupService.getById(_selectedGroupId!)?.members
                        .map((m) => DropdownMenuItem(
                            value: m, child: Text(m))) ??
                    []),
              ],
              onChanged: (v) {
                setState(() => _selectedUserName = v);
                _loadMetrics();
              },
              decoration: const InputDecoration(
                labelText: 'User',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
            ),
          ),
      ],
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (_metricsData2.keys
                    .where((metric) => metric.keys.first != 'Total')
                    .isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: DropdownButton<bool>(
                      value: isDebit,
                      underline: const SizedBox(),
                      onChanged: (bool? newValue) {
                        setState(() {
                          isDebit = newValue!;
                        });
                        _loadMetrics();
                      },
                      items: [
                        DropdownMenuItem(
                          value: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_downward, size: 16, color: Colors.red),
                              const SizedBox(width: 4),
                              const Text('Debit'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_upward, size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              const Text('Credit'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                      Text(
                        '₹ ${_metricsData2.keys.first['Total']?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDebit ? Colors.red : Colors.green),
                      ),
                    ],
                  ),
                ),
                if (_metricsData2.keys
                    .where((metric) => metric.keys.first != 'Total')
                    .isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    ),
                    child: IconButton(
                      onPressed: () async {
                        WarningDialog.showWarning(
                            context: context,
                            title: 'Metrics Report - ${_selectedDurationNotifier.value}',
                            message: 'Proceed to download report\n\n' +
                                'Selected Types:\n - ${_expenseTypesOfDuration.where((type) => !_unSelectedTypes.contains(type)).join('\n - ')}\n\nView: ${_selectedMetricBy.value}',
                            onConfirmed: () async {
                              MessageWidget.showToast(
                                  context: context,
                                  message: 'Downloading in progress...');
                              final isIndividual = _tabController.index == 0;
                              final individualOnly = isIndividual && _selectedGroupId == null;
                              final mappedUser = _tabController.index == 1 ? _selectedUserName : null;
                              await _reportService.prepareMetricsReport(
                                  _expenseService.getExpensesOfSelectedDuration(
                                      _selectedDurationNotifier.value,
                                      customDateRange: selectedDateRange,
                                      groupId: _selectedGroupId,
                                      individualOnly: individualOnly,
                                      mappedUserName: mappedUser),
                                  _expenseTypesOfDuration
                                      .where((type) => !_unSelectedTypes.contains(type))
                                      .toList(),
                                  _selectedMetricBy.value,
                                  _expenseService.uiService.getDateRange(
                                      _selectedDurationNotifier.value!,
                                      customDateRange: selectedDateRange)!);
                            });
                      },
                      icon: const Icon(Icons.download_rounded),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      Expanded(
          child: ValueListenableBuilder(
              valueListenable:
                  Hive.box<Expense2>('expense2Box').listenable(),
              builder: (context, Box<Expense2> box, _) {
                return ValueListenableBuilder(
                    valueListenable: Hive.box<ExpenseType>('expenseTypeBox')
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
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              height: 300,
                              child: _settingsService.getMetricChart() == 'Bar Chart'
                                  ? ExpenseBarChart(
                                      expenseData: Map.from(_barCharData)..remove('Total'))
                                  : _settingsService.getMetricChart() == 'Pie Chart'
                                      ? SingleChildScrollView(
                                          child: ExpensePieChart(
                                              expenseData: Map.from(_barCharData)..remove('Total')))
                                      : SizedBox(
                                          height: 200,
                                          child: SingleChildScrollView(
                                            child: CalendarChartWidget(
                                              dayAmountMap: _calendarChartData,
                                              durationType: _selectedDurationNotifier.value,
                                              customDateRange: selectedDateRange,
                                            ),
                                          ),
                                        ),
                            ),
                          ),
                        ),
                        ...primaryMetric
                            .where((metric) => metric.keys.first != 'Total')
                            .map((metric) {
                          final key = metric.keys.first;
                          final value = metric[key] ?? 0.0;
                          final secondaryMetrics = _metricsData2[metric];
                          final isSelected = _selectedKey == key;
                          return Column(children: [
                            Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  setState(() {
                                    _selectedKey = isSelected ? null : key;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: isSelected ? 0.15 : 0.08),
                                      child: Icon(
                                        isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                                        size: 18,
                                        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    title: Text(
                                      key,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    trailing: Text(
                                      '₹${value.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected
                                            ? (isDebit ? Colors.red : Colors.green)
                                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: isSelected && secondaryMetrics != null
                                  ? Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 2),
                                      color: Theme.of(context).colorScheme.surface,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: secondaryMetrics.map((secondary) {
                                            final secondaryMetricName = secondary.keys.first;
                                            final secondaryMetricValue = secondary[secondaryMetricName] ?? 0.0;
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    secondaryMetricName,
                                                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                                                  ),
                                                  Text(
                                                    '₹${secondaryMetricValue.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: secondaryMetricValue > 0 ? (isDebit ? Colors.red : Colors.green) : null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ]);
                        }).toList(),
                      ]);
                    });
              }))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(4),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Individual'),
              Tab(text: 'Groups'),
            ],
          ),
        ),
        Expanded(child: _buildMetricsContent()),
      ]),
      bottomNavigationBar: Card(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedDateRange != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${_uiService.displayDay(selectedDateRange!.start)} - ${_uiService.displayDay(selectedDateRange!.end)}',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                  ),
                ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                DropdownButton<String>(
                  value: _selectedMetricBy.value,
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedMetricBy.value = newValue!;
                    });
                  },
                  items: metricsBy.map((String value) {
                    return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 14)));
                  }).toList(),
                ),
                DropdownButton<String>(
                  value: _selectedDurationNotifier.value,
                  underline: const SizedBox(),
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
                          style: const TextStyle(fontSize: 14),
                        ));
                  }).toList(),
                ),
                TextButton(
                  onPressed: () => _showMultiSelectDialog(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('Filter', style: TextStyle(fontSize: 13)),
                )
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
