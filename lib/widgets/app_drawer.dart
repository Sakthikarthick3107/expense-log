import 'dart:convert';
import 'dart:io';

import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/screens/daily_expense_screen.dart';
import 'package:expense_log/screens/expense_type_screen.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';

class AppDrawer extends StatelessWidget {

  final Function(int) onSelectScreen;

  const AppDrawer({super.key, required this.onSelectScreen});




  Future<void> requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.request();

    if (status.isGranted) {
      print("Storage permission granted.");
    } else if (status.isDenied) {
      print("Storage permission denied.");
    } else if (status.isPermanentlyDenied) {
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
        child: Container(
          padding:const EdgeInsets.all(10),
          margin:const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

                  Column(

                    children: [
                      ListTile(
                        onTap: () {
                          onSelectScreen(0);
                        },
                        leading: const Icon(
                            Icons.currency_rupee
                        ),
                        title: const Text('Daily Expense'),
                      ),
                      ListTile(
                        onTap: () {
                          onSelectScreen(1);
                        },
                        leading: Icon(
                            Icons.type_specimen
                        ),
                        title: Text('Expense Type'),
                      ),
                      ListTile(
                        onTap: () {
                          onSelectScreen(2);

                        },
                        leading: Icon(
                            Icons.calculate_rounded
                        ),
                        title: Text('Metrics'),
                      )
                    ],
                  ),

                  ListTile(
                onTap: () {
                  MessageWidget.showToast(message: 'This feature will be available soon', status: 0);
                },
                leading: Icon(
                    Icons.settings
                ),
                title: Text('Settings'),
              )

                ],

          ),
        ),
      ),
    );
  }


}
