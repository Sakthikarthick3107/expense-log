
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/services/expense_service.dart';
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
  final List<String>  metricsDuration = ['This week','Last week','This month' , 'Last month'];
  final List<String> metricsBy = ['By type' , 'By day'];
  final ValueNotifier<String> _selectedDurationNotifier = ValueNotifier<String>('This week');
  final ValueNotifier<String> _selectedMetricBy = ValueNotifier<String>('By type');
  late Map<String,double> _metricsData = {};
  late List<String> _expenseTypesOfDuration;
  late List<String> _unSelectedTypes = [];
  late Map<Map<String, double>,List< Map<String, double>>> _metricsData2 = {};

  String? _selectedKey ;

  @override
  void initState(){
    super.initState();
    _expenseService = Provider.of<ExpenseService>(context , listen: false);
    _expenseTypesOfDuration = _expenseService.expenseTypesOfSelectedDuration(_selectedDurationNotifier.value);
    _metricsData = _expenseService.getMetrics(_selectedDurationNotifier.value , _selectedMetricBy.value ,_unSelectedTypes);
    _metricsData2 = _expenseService.getMetrics2(_selectedDurationNotifier.value , _selectedMetricBy.value , _unSelectedTypes);
    _selectedDurationNotifier.addListener((){
        _expenseTypesOfDuration = _expenseService.expenseTypesOfSelectedDuration(_selectedDurationNotifier.value);
          _metricsData = _expenseService.getMetrics(_selectedDurationNotifier.value,_selectedMetricBy.value , _unSelectedTypes);
          _metricsData2 = _expenseService.getMetrics2(_selectedDurationNotifier.value , _selectedMetricBy.value , _unSelectedTypes);
    });
    _selectedMetricBy.addListener((){
        _metricsData = _expenseService.getMetrics(_selectedDurationNotifier.value,_selectedMetricBy.value , _unSelectedTypes);
        _metricsData2 = _expenseService.getMetrics2(_selectedDurationNotifier.value , _selectedMetricBy.value,_unSelectedTypes);
    });
  }

  void _showMultiSelectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx , setStateDialog) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
                      );
                      _metricsData2 = _expenseService.getMetrics2(
                        _selectedDurationNotifier.value,
                        _selectedMetricBy.value,
                        _unSelectedTypes,
                      );
                    });
                  },
                  child: Text("OK"),
                ),
              ],
            );

          }
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding:const EdgeInsets.all(20),
        child: Column(
          children :[
            Container(
              child: Text(
                '₹ ${_metricsData2.keys.first['Total']?.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
            //  Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children:[
            //     DropdownButton<String>(
            //       value: _selectedMetricBy.value,
            //
            //       onChanged: (String? newValue){
            //         setState(() {
            //           _selectedMetricBy.value = newValue!;
            //         });
            //       },
            //       items: metricsBy.map((String value){
            //         return DropdownMenuItem<String>(
            //             value: value,
            //             child: Text(value , style : TextStyle(fontSize:14))
            //         );
            //
            //       }).toList(),
            //     ),
            //     DropdownButton<String>(
            //           value: _selectedDurationNotifier.value,
            //
            //           onChanged: (String? newValue){
            //               setState(() {
            //                 _selectedDurationNotifier.value = newValue!;
            //               });
            //           },
            //           items: metricsDuration.map((String value){
            //             return DropdownMenuItem<String>(
            //                 value: value,
            //                 child: Text(value , style : TextStyle(fontSize:14))
            //             );
            //
            //           }).toList(),
            //     )
            //   ]
            // ),
            Expanded(
                child: ValueListenableBuilder(
                    valueListenable: Hive.box<Expense2>('expense2Box').listenable(),
                    builder: (context , Box<Expense2> box,_){
                      return ValueListenableBuilder(
                          valueListenable: Hive.box<ExpenseType>('expenseTypeBox').listenable(),
                          builder: (context,Box<ExpenseType> expenseBox , _){
                            // final metrics = _expenseService.getMetrics(_selectedDurationNotifier.value);
                            final primaryMetric = _metricsData2.keys;
                            if(primaryMetric.where((metric )=> metric.keys.first != 'Total').isEmpty){
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/amongus.png',
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover
                                    ),
                                    const Text(
                                      'No metrics for the selected filters',
                                      style: TextStyle(
                                        fontSize: 20
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],

                                ),
                              );
                            }

                            return ListView(
                              children: primaryMetric.where((metric )=> metric.keys.first != 'Total').map((metric){
                                final key = metric.keys.first;
                                final value = metric[key] ?? 0.0;
                                final secondaryMetrics = _metricsData2[metric];
                                return Column(
                                  children :[
                                  ListTile(
                                    onTap: (){
                                      setState(() {
                                        _selectedKey = _selectedKey == key ? null : key;
                                        // print(_selectedKey);
                                      });
                                    },
                                    title: Text(key, style: TextStyle(fontSize: 18),),
                                    trailing: Text(
                                      '₹${value.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:  FontWeight.normal
                                        ),
                                    ),
                                  ),
                                    AnimatedSize(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                        child: _selectedKey == key && secondaryMetrics != null ?
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 30),
                                          child: Column(
                                            children: secondaryMetrics.map((secondary) {
                                              final secondaryMetricName = secondary.keys.first;
                                              final secondaryMetricValue = secondary[secondaryMetricName] ?? 0.0;
                                              return Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    secondaryMetricName,
                                                    style: TextStyle(fontSize: 14,color: Colors.grey[700],),
                                                  ),
                                                  Text(
                                                    '₹${secondaryMetricValue.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[700],
                                                    ),
                                                  )
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        )
                                            : SizedBox.shrink()
                                    ),

                                ]
                                );
                              }).toList(),
                            );


                          });
                    })

            )
          ]
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 20 , vertical: 10),
        color: Colors.deepOrange,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              DropdownButton<String>(
                value: _selectedMetricBy.value,

                onChanged: (String? newValue){
                  setState(() {
                    _selectedMetricBy.value = newValue!;
                  });
                },
                items: metricsBy.map((String value){
                  return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,style: TextStyle(fontSize: 16))
                  );

                }).toList(),
              ),
              DropdownButton<String>(
                value: _selectedDurationNotifier.value,

                onChanged: (String? newValue){
                  setState(() {
                    _selectedDurationNotifier.value = newValue!;
                  });
                },
                items: metricsDuration.map((String value){
                  return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,style: TextStyle(fontSize: 16),)
                  );

                }).toList(),
              ),
              TextButton(onPressed: (){
                _showMultiSelectDialog(context);
              }, child: Text('Filter Types'))
            ]
        ),
      ),
    );
  }
}
