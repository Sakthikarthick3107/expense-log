import 'dart:async';
import 'dart:io';

import 'package:expense_log/models/user.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/updates/app_update.dart';
import 'package:expense_log/widgets/color_selector.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:expense_log/widgets/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  int settingIndex = 0;
  String version = '';
  int downloads = 0;
  User? user;

  @override
  void initState(){
    super.initState();
    _settingsService = Provider.of<SettingsService>(context,listen: false);
    _fetchVersion();
    downloadsCount();
    _checkIfUserExists();
  }


  Future<void> downloadsCount()async{
    int count = await _settingsService.fetchDownloadCount()  as int;
    setState(() {
      downloads = count;
    });
  }

  Future<void> _copyLinkToClipboard(BuildContext context) async {
    String getDownloadLink = await _settingsService.downloadUrl();
    if(getDownloadLink.length > 0){
      await Clipboard.setData(ClipboardData(text: getDownloadLink));
      MessageWidget.showSnackBar(context: context, message: 'Link copied to clipboard!',status:1);
    }
    else{
      MessageWidget.showSnackBar(context: context, message: 'Issue in getting link',status:0);
    }
  }

  Future<void> _fetchVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
    });
  }

  Future<void> _checkIfUserExists() async{
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

  Future<void> _launchMail(String url) async{
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: url,
      query: 'subject=Hello&body=How are you?'
    );
    if(await canLaunchUrl(emailUri)){
      await launchUrl(emailUri);
    }
  }

  void showReorderPopup(BuildContext context, List<String> screens, Function(List<String>) onSave) {
    showDialog(
      context: context,
      builder: (context) => ScreenOrderPopup(screens: screens, onSave: onSave),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:!Platform.isWindows ? AppBar(
        title: Text(user != null? user!.userName :'Settings',

        ),
      ) : null,
      body: Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('General'),
              ListTile(
                onTap: (){
                  setState(() {
                    settingIndex = settingIndex == 1 ? 0 : 1;
                  });
                },
                title: Text('About'),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child : settingIndex == 1 ?
                Consumer<SettingsService>(
                    builder: (context,settingsService , child){
                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Downloads'),
                                Text(downloads.toString())
          
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Version'),
                                Text(version)
                              ],
                            )
                          ],
                        ),
                      );
                    })
                    : SizedBox.shrink()
              ),
              ListTile(
                onTap: (){
                  setState(() {
                    settingIndex = settingIndex ==3 ? 0 : 3;
                  });
                  final appUpdate = AppUpdate();
                  appUpdate.checkForUpdates(context);
                },
                title: Text('Updates'),
              ),
              AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: settingIndex == 3 ?
                  Container(
                      padding :EdgeInsets.symmetric(horizontal: 40, vertical: 0),
                      child : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Current Version'),
                              Text(version)
                            ],
                          )
                        ],
                      )
                  )
                    : SizedBox.shrink(),
              ),
              ListTile(
                onTap: () async {
                  // setState(() {
                  //   _copyLinkToClipboard(context);
                  // });
                  String getDownloadLink = await _settingsService.downloadUrl();
                  Share.share(getDownloadLink);
                },
                title: Text('Share App'),
              ),
              ListTile(
                onTap: (){
                  setState(() {
                    settingIndex = settingIndex ==4 ? 0 : 4;
                  });
                },
                title: Text('Developer Info'),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: settingIndex == 4 ?
                Container(
                  padding :EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sakthikarthick Nagendran',
                        style: TextStyle(
                            fontSize: 18
                        ),

                      ),
                      Text(
                        'Chennai',
                        style: TextStyle(
                            fontSize: 14
                        ),

                      ),
                      SizedBox(height: 20),
                      Wrap(
                        spacing: 6,
                        runSpacing: 10,
                        children: [
                          InkWell(
                            onTap: (){
                              _launchMail('sakthikarthick3107@gmail.com');
                            },
                            child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 15,vertical: 6),

                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.orange, width: 2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Mail')),
                          ),
                          SizedBox(width: 10,),
                          InkWell(
                            onTap: (){
                              _launchURL('https://sakthikarthick3107.netlify.app');

                            },
                            child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 15,vertical: 6),

                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.orange, width: 2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Portfolio')),
                          ),
                          SizedBox(width: 10,),
                          InkWell(
                            onTap: (){
                              _launchURL('https://www.instagram.com/__intelligent__psycho__/');
                            },
                            child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 15,vertical: 6),

                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.orange, width: 2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Instagram')),
                          ),

                        ],
                      ),

                    ],
                  ),
                )
                    : SizedBox.shrink() ,
              ),

              if(user == null && !Platform.isWindows)
                ListTile(
                  onTap: ()async{
                    int loginUser = await _settingsService.googleSignIn();
                    if(loginUser == 1){
                      _checkIfUserExists();
                      MessageWidget.showSnackBar(context: context, message: 'Loggedin successfully',status: 1);
                    }
                    else{
                      MessageWidget.showSnackBar(context: context, message: 'Failed to login',status: 0);
                    }
                  },
                  title: Text('Signin using Google'),
                ),

              if(user != null)
                ListTile(
                  onTap: ()async{
                    await WarningDialog.showWarning(context: context,
                        title: 'Warning',
                        message: 'Are you sure to signout?',
                        onConfirmed: ()async{
                          int signOutUser = await _settingsService.googleSignOut();
                          if(signOutUser == 1){
                            setState(() {
                              user = null;
                            });
                            MessageWidget.showSnackBar(context: context, message: 'Loggedout successfully' , status: 1);
                          }
                          else
                            MessageWidget.showSnackBar(context: context, message: 'Failed to logout',status: 0);
                        });

                  },
                  title: Text('Signout'),
                  subtitle: Text(
                    '${user!.email}',
                    style: TextStyle(
                        fontSize: 14
                    ),
                  ),
                ),
              Text('Display'),
              ListTile(
                title: Text(_settingsService.isDarkTheme() ? 'Dark' : 'Light'),
                trailing: Switch(
                  value: _settingsService.isDarkTheme(),
                  onChanged: (value) {
                    _settingsService.setTheme(value);
                  },
                ),
                onTap: () {
                  final current = _settingsService.isDarkTheme();
                  _settingsService.setTheme(!current);
                },
              ),
              ListTile(
                title: Text('List Elevation'),
                trailing: Switch(
                  value: _settingsService.getElevation(),
                  onChanged: (value) {
                    _settingsService.enableElevation(value);
                  },
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
                      setState(() async{
                        await _settingsService.setPrimaryColor(color);
                      });
                    },
                    smallSize: true,
                  ),
                ),
              ),

              ListTile(
                title: const Text('Load Metrics'),
                subtitle: const Text('Prefer which duration expenses loads in Metrics by default',style: TextStyle(fontSize: 10),),
                trailing: DropdownButton<String>(
                  value: _settingsService.landingMetric(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _settingsService.setLandingMetric(newValue);
                    }
                  },
                  items: ['This week', 'Last week', 'This month' , 'Last month'].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value , style: TextStyle(fontSize: 15),),
                    );
                  }).toList(),
                ),
                onTap: () {},
              ),

              ListTile(
                title: const Text('Metrics Chart'),
                subtitle: const Text('Set your preference chart for metrics visualization',style: TextStyle(fontSize: 10),),
                trailing: DropdownButton<String>(
                  value: _settingsService.getMetricChart(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _settingsService.setMetricChart(newValue);
                    }
                  },
                  items: ['Bar Chart', 'Pie Chart'].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value , style: TextStyle(fontSize: 15),),
                    );
                  }).toList(),
                ),
                onTap: () {}, // Optional: you can leave it empty
              ),

              ListTile(
                onTap: (){
                  List<String> screens = _settingsService.getScreenOrder();
          
                  showReorderPopup(context, screens, (newOrder) async {
                    print("Updated Order: $newOrder");
                    await _settingsService.saveScreenOrder(newOrder);
                    MessageWidget.showSnackBar(context: context, message: 'Closing application for reorder settings');
                    Future.delayed(Duration(seconds: 4), () {
                      exit(0);
                    });
                  });
                },
                title: Text('Customize Navigation'),
              ),

              Text('Data'),
              ListTile(
                onTap: () async {
                  int setBackup = await _settingsService.backupHiveToGoogleDrive();
                  if(setBackup == 1){
                    MessageWidget.showSnackBar(context: context, message: 'Backup successfully',status: 1);
                  }
                  else{
                    MessageWidget.showSnackBar(context: context, message: 'Backup failed',status: 0);
                  }
                },
                title: Text('Backup Data'),
              ),

              ListTile(
                onTap: () async {
                  int setRestore = await _settingsService.pickBackupFileAndRestore();
                  if(setRestore == 1){
                    MessageWidget.showSnackBar(context: context, message: 'Restored successfully - Closing application',status: 1);
                    setState(() {}); // Rebuilds the widget
                    SystemNavigator.pop(animated: true);
                  }
                  else{
                    MessageWidget.showSnackBar(context: context, message: 'Restore failed',status: 0);
                  }
                },
                title: Text('Restore'),
              )

            ],
          ),
        ),
      ),
    );;
  }
}
