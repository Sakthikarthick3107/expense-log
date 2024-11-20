import 'dart:convert';
import 'dart:io';

import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/screens/daily_expense_screen.dart';
import 'package:expense_log/screens/expense_type_screen.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';

class AppDrawer extends StatelessWidget {

  final Function(int) onSelectScreen;

  const AppDrawer({super.key, required this.onSelectScreen});


  Future<void> requestStoragePermission() async {
    // Request the storage permission
    PermissionStatus status = await Permission.storage.request();

    if (status.isGranted) {
      print("Storage permission granted.");
    } else if (status.isDenied) {
      print("Storage permission denied.");
    } else if (status.isPermanentlyDenied) {
      // Direct the user to settings if permission is permanently denied
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(

      child: Drawer(

        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero
        ),
        child: ListView(
          children: <Widget>[
            ListTile(
              onTap: () {
                onSelectScreen(0);
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(builder: (context) => DailyExpenseScreen()),
                // );
              },
              leading: const Icon(
                  Icons.currency_rupee
              ),
              title: const Text('Daily Expense'),
            ),
            ListTile(
              onTap: () {
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
              onTap: () {
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
            )

          ],
        ),
      ),
    );
  }


}
