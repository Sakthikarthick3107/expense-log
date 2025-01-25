import 'dart:convert';
import 'dart:io';

import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/screens/daily_expense_screen.dart';
import 'package:expense_log/screens/expense_type_screen.dart';
import 'package:expense_log/screens/settings_screen.dart';
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

        // backgroundColor: Colors.white,
        shape:  RoundedRectangleBorder(
            borderRadius: BorderRadius.zero
        ),
        child: Container(
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.symmetric(vertical: 20),
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
                        leading:  Icon(
                            Icons.currency_rupee,
                         color: Theme.of(context).iconTheme.color
                        ),
                        title:  Text('Daily Expense'),
                      ),
                      ListTile(
                        onTap: () {
                          onSelectScreen(1);
                        },
                        leading: Icon(
                            Icons.type_specimen_outlined,
                            color: Theme.of(context).iconTheme.color
                        ),
                        title: Text('Expense Type'),
                      ),
                      ListTile(
                        onTap: () {
                          onSelectScreen(2);

                        },
                        leading: Icon(
                            Icons.calculate_rounded,
                            color: Theme.of(context).iconTheme.color
                        ),
                        title: Text('Metrics'),
                      ),
                      ListTile(
                        onTap: () {
                          onSelectScreen(3);

                        },
                        leading: Icon(
                            Icons.save,
                            color: Theme.of(context).iconTheme.color
                        ),
                        title: Text('Collections'),
                      )
                    ],
                  ),

                  ListTile(
                onTap: () {
                  if(!Platform.isWindows){
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
                  }
                  else{
                    onSelectScreen(3);
                  }

                  // MessageWidget.showToast(message: 'This feature will be available soon', status: 0);
                },
                leading: Icon(
                    Icons.settings,
                    color: Theme.of(context).iconTheme.color
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
