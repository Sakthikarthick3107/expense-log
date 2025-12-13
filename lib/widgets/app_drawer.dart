import 'dart:io';
import 'package:expense_log/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';

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
  void initState() {
    super.initState();
    _settingsService = Provider.of<SettingsService>(context, listen: false);
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
    "Audit Log": Icons.history,
    "Downloads": Icons.download,
    "Schedules": Icons.schedule,
    "Accounts": Icons.account_balance_wallet_rounded,
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
                  title: Text(
                    item,
                    style: TextStyle(fontSize: 16),
                  ),
                  leading: Icon(
                    screenIcons[item],
                    color: Theme.of(context).iconTheme.color,
                    size: 20,
                  ),
                );
              }).toList(),
            ),
            ListTile(
              onTap: () {
                if (!Platform.isWindows) {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SettingsScreen()));
                } else {
                  widget.onSelectScreen(5);
                }
              },
              leading: Icon(Icons.settings,
                  color: Theme.of(context).iconTheme.color),
              title: Text('Settings'),
            )
          ],
        ),
      ),
    );
  }
}
