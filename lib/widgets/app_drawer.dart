import 'package:expense_log/screens/daily_expense_screen.dart';
import 'package:expense_log/screens/expense_type_screen.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {

  final Function(int) onSelectScreen;

  const AppDrawer({super.key , required this.onSelectScreen});

  @override
  Widget build(BuildContext context) {
    return  Container(

      child:  Drawer(

        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero
        ),
        child: ListView(
          children: <Widget> [
             ListTile(
               onTap: (){
                  onSelectScreen(0);
                 // Navigator.pushReplacement(
                 //   context,
                 //   MaterialPageRoute(builder: (context) => DailyExpenseScreen()),
                 // );
               },
              leading:const Icon(
                Icons.currency_rupee
              ),
              title:const Text('Daily Expense'),
            ),
             ListTile(
               onTap: (){
                  onSelectScreen(1);
                 // Navigator.pushReplacement(
                 //   context,
                 //   MaterialPageRoute(builder: (context) => ExpenseTypeScreen()),
                 // );
               },
              leading: Icon(
                  Icons.type_specimen
              ),
              title: Text('Expense Type'),
            ),
            ListTile(
              onTap: (){
                onSelectScreen(2);
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(builder: (context) => ExpenseTypeScreen()),
                // );
              },
              leading: Icon(
                  Icons.calculate_rounded
              ),
              title: Text('Metrics'),
            ),
          ],
        ),
      ),
    );
  }
}
