
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
  final ValueNotifier<String> _selectedDurationNotifier = ValueNotifier<String>('This week');
  late Map<String,double> _metricsData = {};


  @override
  void initState(){
    super.initState();
    _expenseService = Provider.of<ExpenseService>(context , listen: false);
    _metricsData = _expenseService.getMetrics(_selectedDurationNotifier.value);
    _selectedDurationNotifier.addListener((){
          _metricsData = _expenseService.getMetrics(_selectedDurationNotifier.value);

    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding:const EdgeInsets.all(20),
        child: Column(
          children :[
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                const Text(
                'Metrics',
                style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24
                ),
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
                            child: Text(value)
                        );

                      }).toList(),
                )
              ]
            )

            ,
            Expanded(
                child: ValueListenableBuilder(
                    valueListenable: Hive.box<Expense2>('expense2Box').listenable(),
                    builder: (context , Box<Expense2> box,_){
                      return ValueListenableBuilder(
                          valueListenable: Hive.box<ExpenseType>('expenseTypeBox').listenable(),
                          builder: (context,Box<ExpenseType> expenseBox , _){
                            // final metrics = _expenseService.getMetrics(_selectedDurationNotifier.value);
                            final totalValue = _metricsData.remove('Total');
                            if(totalValue != null){
                              _metricsData['Total'] = totalValue;
                            }
                            return ListView(
                              children: _metricsData.entries.map((metric){
                                return ListTile(
                                  onTap: (){},
                                  title: Text(metric.key),
                                  trailing: Text(
                                    '₹${metric.value.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: metric.key=='Total' ? FontWeight.bold : FontWeight.normal
                                      ),
                                  ),
                                );
                              }).toList(),
                            );
                          });
                    })

            )
          ]
        ),
      ),
    );
  }
}
