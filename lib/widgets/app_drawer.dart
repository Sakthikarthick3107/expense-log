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
    "Metrics": Icons.auto_graph_outlined,
    "Groups": Icons.groups,
    "Audit Log": Icons.history,
    "Downloads": Icons.download,
    "Schedules": Icons.schedule,
    "Accounts": Icons.account_balance_wallet_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        padding: EdgeInsets.only(top: 48, bottom: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.menu_book_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'expense.log',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 0.5),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _screenNames.asMap().entries.map((entry) {
                  int index = entry.key;
                  String item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    child: ListTile(
                      onTap: () => widget.onSelectScreen(index),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                        ),
                        child: Icon(
                          screenIcons[item],
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(thickness: 0.5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.settings, color: Colors.grey, size: 20),
                ),
                title: const Text('Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
