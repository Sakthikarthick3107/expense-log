import 'package:expense_log/screens/daily_expense_screen.dart';
import 'package:expense_log/screens/expense_type_screen.dart';
import 'package:expense_log/screens/metrics_screen.dart';
import 'package:expense_log/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String version = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchVersion();
  }
  Future<void> _fetchVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
    });
  }
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
  Widget build(BuildContext context){
    return Scaffold(
      drawer: AppDrawer(onSelectScreen: _onDrawerItemSelected),
        appBar: AppBar(
          title:const  Text(
            'ExpenseLog',
            style:const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold
            ),

          ),
          actions: [
            Container(
              // padding: EdgeInsets.all(10),
              margin: EdgeInsets.all(20),
              child: Text(
                'Version $version',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14
                ),
              ),
            )
          ],
          //leading: Text(version),
        ),
      body: _screens[_currentIndex],
    );
  }
}
