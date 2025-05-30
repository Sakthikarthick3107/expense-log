import 'dart:async';
import 'dart:io';

import 'package:expense_log/models/user.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/updates/app_update.dart';
import 'package:expense_log/widgets/color_selector.dart';
import 'package:expense_log/widgets/info_dialog.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:expense_log/widgets/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart';
import '../utility/preset_colors.dart';
import '../widgets/screen_order_popup.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsService _settingsService;

  String version = '';
  int downloads = 0;
  User? user;

  @override
  void initState() {
    super.initState();
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _fetchVersion();
    downloadsCount();
    _checkIfUserExists();
  }

  Future<void> downloadsCount() async {
    int count = await _settingsService.fetchDownloadCount() as int;
    setState(() {
      downloads = count;
    });
  }

  Future<void> _fetchVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
    });
  }

  Future<void> _checkIfUserExists() async {
    User? userData = await _settingsService.getUser();
    setState(() {
      user = userData;
    });
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchMail(String url) async {
    final Uri emailUri = Uri(
        scheme: 'mailto', path: url, query: 'subject=Hello&body=How are you?');
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void showReorderPopup(BuildContext context, List<String> screens,
      Function(List<String>) onSave) {
    showDialog(
      context: context,
      builder: (context) => ScreenOrderPopup(screens: screens, onSave: onSave),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !Platform.isWindows
          ? AppBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings'),
                  Text(
                    user != null ? user!.userName : 'User',
                    style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                  )
                ],
              ),
              actions: [
                IconButton(
                    onPressed: () async {
                      String getDownloadLink =
                          await _settingsService.downloadUrl("v" + version);
                      Share.share(getDownloadLink);
                    },
                    icon: Icon(Icons.share_sharp)),
                SizedBox(
                  width: 10,
                )
              ],
            )
          : null,
      body: Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('General'),
              ListTile(
                onTap: () {
                  final appUpdate = AppUpdate();
                  appUpdate.checkForUpdates(context);
                  InfoDialog.showInfo(
                    title: 'App updates',
                    context: context,
                    content: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Downloads'),
                          Text(downloads.toString())
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text('Current Version'), Text(version)],
                      ),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Stable Releases'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('2.2.0'),
                          GestureDetector(
                            onTap: () {
                              _settingsService.copyLinkToClipboard(
                                  context, 'v2.2.0');
                            },
                            child: Text(
                              'Copy Link',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('2.1.3'),
                          GestureDetector(
                            onTap: () {
                              _settingsService.copyLinkToClipboard(
                                  context, 'v2.1.3');
                            },
                            child: Text(
                              'Copy Link',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('1.2.5'),
                          GestureDetector(
                            onTap: () {
                              _settingsService.copyLinkToClipboard(
                                  context, 'v1.2.5');
                            },
                            child: Text(
                              'Copy Link',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  );
                },
                title: Text('App Updates'),
              ),
              ListTile(
                onTap: () {
                  InfoDialog.showInfo(
                      context: context,
                      title: 'Developer',
                      content: [
                        Text(
                          'Sakthikarthick Nagendran',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'Chennai',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 20),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            InkWell(
                              onTap: () {
                                _launchMail('sakthikarthick3107@gmail.com');
                              },
                              child: Icon(Icons.mail),
                            ),
                            InkWell(
                              onTap: () {
                                _launchURL(
                                    'https://sakthikarthick3107.netlify.app');
                              },
                              child: Icon(FontAwesomeIcons.addressCard),
                            ),
                            InkWell(
                              onTap: () {
                                _launchURL(
                                    'https://www.instagram.com/__intelligent__psycho__/');
                              },
                              child: Icon(FontAwesomeIcons.instagram),
                            )
                          ],
                        ),
                      ]);
                },
                title: Text('Developer Info'),
              ),
              if (user == null && !Platform.isWindows)
                ListTile(
                  onTap: () async {
                    int loginUser = await _settingsService.googleSignIn();
                    if (loginUser == 1) {
                      _checkIfUserExists();
                      MessageWidget.showToast(
                          context: context,
                          message: 'Loggedin successfully',
                          status: 1);
                    } else {
                      MessageWidget.showToast(
                          context: context,
                          message: 'Failed to login',
                          status: 0);
                    }
                  },
                  title: Text('Signin using Google'),
                ),
              if (user != null)
                ListTile(
                  onTap: () async {
                    await WarningDialog.showWarning(
                        context: context,
                        title: 'Warning',
                        message: 'Are you sure to signout?',
                        onConfirmed: () async {
                          int signOutUser =
                              await _settingsService.googleSignOut();
                          if (signOutUser == 1) {
                            setState(() {
                              user = null;
                            });
                            MessageWidget.showToast(
                                context: context,
                                message: 'Loggedout successfully',
                                status: 1);
                          } else
                            MessageWidget.showToast(
                                context: context,
                                message: 'Failed to logout',
                                status: 0);
                        });
                  },
                  title: Text('Signout'),
                  subtitle: Text(
                    '${user!.email}',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              Text('Display'),
              ListTile(
                title: Text(_settingsService.isDarkTheme() ? 'Dark' : 'Light'),
                trailing: Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: _settingsService.isDarkTheme(),
                    onChanged: (value) {
                      _settingsService.setTheme(value);
                    },
                  ),
                ),
                onTap: () {
                  final current = _settingsService.isDarkTheme();
                  _settingsService.setTheme(!current);
                },
              ),
              ListTile(
                title: Text('List Elevation'),
                trailing: Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: _settingsService.getElevation(),
                    onChanged: (value) {
                      _settingsService.enableElevation(value);
                    },
                  ),
                ),
                onTap: () {
                  final current = _settingsService.getElevation();
                  _settingsService.enableElevation(!current);
                },
              ),
              ListTile(
                title: const Text('Color'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ColorSelector(
                    presetColors: presetColors,
                    selectedColor: _settingsService.getPrimaryColor(),
                    onColorSelected: (color) {
                      setState(() async {
                        await _settingsService.setPrimaryColor(color);
                      });
                    },
                    smallSize: true,
                  ),
                ),
              ),
              ListTile(
                title: const Text('Load Metrics'),
                subtitle: const Text(
                  'Prefer which duration expenses loads in Metrics by default',
                  style: TextStyle(fontSize: 10),
                ),
                trailing: DropdownButton<String>(
                  value: _settingsService.landingMetric(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _settingsService.setLandingMetric(newValue);
                    }
                  },
                  items: ['This week', 'Last week', 'This month', 'Last month']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(fontSize: 15),
                      ),
                    );
                  }).toList(),
                ),
                onTap: () {},
              ),
              ListTile(
                onTap: () {
                  List<String> screens = _settingsService.getScreenOrder();

                  showReorderPopup(context, screens, (newOrder) async {
                    print("Updated Order: $newOrder");
                    await _settingsService.saveScreenOrder(newOrder);
                    MessageWidget.showToast(
                        context: context,
                        message: 'Closing application for reorder settings');
                    Future.delayed(Duration(seconds: 4), () {
                      exit(0);
                    });
                  });
                },
                title: Text('Customize Navigation'),
              ),
              Text('Background'),
              ListTile(
                title: Text("Telegram Chat"),
                onTap: () async {
                  _launchURL('http://t.me/ExpenseChatterBot');
                },
                subtitle: Text(
                  'Chat with ExpenseLog Telegram bot .Please keep expense log open while chatting with Telegram bot for getting replies.',
                  style: TextStyle(fontSize: 8),
                ),
              ),
              ListTile(
                  title: Text('Activity Logging'),
                  onTap: () async {
                    bool getAuditSetup = _settingsService.isAuditEnabled();
                    bool res =
                        await _settingsService.setAuditEnable(!getAuditSetup);
                    MessageWidget.showToast(
                        context: context,
                        message:
                            'Audit Log Tracker is ${!getAuditSetup ? 'enabled' : 'disabled'}');
                  },
                  trailing: Transform.scale(
                    scale: 0.75,
                    child: Switch(
                        value: _settingsService.isAuditEnabled(),
                        onChanged: (bool newValue) async {
                          bool res =
                              await _settingsService.setAuditEnable(newValue);
                          MessageWidget.showToast(
                              context: context,
                              message:
                                  'Audit Log Tracker is ${newValue ? 'enabled' : 'disabled'}');
                        }),
                  )),
              Text('Data'),
              ListTile(
                onTap: () async {
                  int setBackup =
                      await _settingsService.backupHiveToGoogleDrive();
                  if (setBackup == 1) {
                    MessageWidget.showToast(
                        context: context,
                        message: 'Backup successfully',
                        status: 1);
                  } else {
                    MessageWidget.showToast(
                        context: context, message: 'Backup failed', status: 0);
                  }
                },
                title: Text('Backup Data'),
              ),
              ListTile(
                onTap: () async {
                  int setRestore =
                      await _settingsService.pickBackupFileAndRestore();
                  if (setRestore == 1) {
                    MessageWidget.showToast(
                        context: context,
                        message: 'Restored successfully - Closing application',
                        status: 1);
                    setState(() {}); // Rebuilds the widget
                    SystemNavigator.pop(animated: true);
                  } else {
                    MessageWidget.showToast(
                        context: context, message: 'Restore failed', status: 0);
                  }
                },
                title: Text('Restore'),
              )
            ],
          ),
        ),
      ),
    );
    ;
  }
}
