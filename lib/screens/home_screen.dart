import 'package:expense_log/screens/daily_expense_screen.dart';
import 'package:expense_log/screens/expense_type_screen.dart';
import 'package:expense_log/screens/metrics_screen.dart';
import 'package:expense_log/widgets/app_drawer.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DailyExpenseScreen(),
    const ExpenseTypeScreen(),
    const MetricsScreen(),
  ];

  void _onDrawerItemSelected(int index){
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(onSelectScreen: _onDrawerItemSelected),
        appBar: AppBar(
          title: const Text(
            'ExpenseLog',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
      body: _screens[_currentIndex],
    );
  }
}
