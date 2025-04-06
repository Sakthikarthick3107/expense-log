import 'dart:convert';
import 'dart:io';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/screens/daily_expense_screen.dart';
import 'package:expense_log/screens/expense_type_screen.dart';
import 'package:expense_log/screens/settings_screen.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/material.dart';
// import 'package:googleapis/eventarc/v1.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart'; // Import your service

class AppDrawer extends StatefulWidget {
  final Function(int) onSelectScreen;

  const AppDrawer({super.key, required this.onSelectScreen});

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {

  late SettingsService _settingsService;
  late List<String> _screenNames = [];


  @override
  void initState(){
    super.initState();
    _settingsService = Provider.of<SettingsService>(context,listen: false);
    loadMenuOrder();
  }


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

  Future<void> loadMenuOrder() async {
    List<String> order = await _settingsService.getScreenOrder();
    setState(() {
      _screenNames = order;
    });
  }

  final Map<String, IconData> screenIcons = {
    "Expenses": Icons.calculate,
    "Types": Icons.category_outlined,
    "Collections": Icons.collections_bookmark_rounded,
    "Metrics": Icons.auto_graph_outlined,
    "UPI Logs" : Icons.payment
  };

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: _screenNames.asMap().entries.map((entry) {
                int index = entry.key;
                String item = entry.value;
                return ListTile(
                  onTap: () => widget.onSelectScreen(index),
                  title: Text(item),

                  leading: Icon(screenIcons[item], color: Theme.of(context).iconTheme.color,),
                );
              }).toList(),
            ),
            ListTile(
              onTap: () {
                if (!Platform.isWindows) {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
                } else {
                  widget.onSelectScreen(3);
                }
              },
              leading: Icon(Icons.settings, color: Theme.of(context).iconTheme.color),
              title: Text('Settings'),
            )
          ],
        ),
      ),
    );
  }
}
