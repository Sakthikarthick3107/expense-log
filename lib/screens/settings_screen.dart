import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/updates/app_update.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsService _settingsService;

  int settingIndex = 0;
  String version = '';

  @override
  void initState(){
    super.initState();
    _settingsService = Provider.of<SettingsService>(context,listen: false);
    _fetchVersion();
  }

  Future<void> _fetchVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            ListTile(
              onTap: (){
                setState(() {
                  settingIndex = 1;
                });
              },
              title: Text('About'),
            ),
            if(settingIndex == 1)
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
                              FutureBuilder<int?>(
                                  future: settingsService.fetchDownloadCount(),
                                  builder: (context,snapshot){

                                    if(snapshot.data == -1){
                                      MessageWidget.showSnackBar(context: context, message: "Failed fetching download count", status: 0);
                                    }

                                    return Text(
                                        snapshot.data == null ? '...' : snapshot.data.toString()

                                    );
                                  }
                              )
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
                  }),
            ListTile(
              onTap: (){
                setState(() {
                  settingIndex = 2;
                });
              },
              title: Text('Theme'),
            ),
            if(settingIndex == 2)
              Consumer<SettingsService>(
                builder: (context , settingsService,child){

                    return Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 0),
                      child: Column(
                        children: [
                          ListTile(
                            onTap:(){
                              _settingsService.setTheme(false);
                            },
                              leading: Icon(
                                  !settingsService.isDarkTheme()
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank
                              ),
                              title: Text(
                                  'Light', style: TextStyle(fontSize: 18))
                          ),
                          ListTile(
                              onTap:(){
                                _settingsService.setTheme(true);
                              },
                              leading: Icon(
                                  settingsService.isDarkTheme() ?Icons
                                      .check_box : Icons.check_box_outline_blank
                              ),
                              title: Text(
                                  'Dark', style: TextStyle(fontSize: 18))
                          )
                        ],
                      ),

                    );

                },

              ),

            ListTile(
              onTap: (){
                setState(() {
                  settingIndex = 3;
                });
                final appUpdate = AppUpdate();
                appUpdate.checkForUpdates(context);
              },
              title: Text('Updates'),
            ),
            if(settingIndex == 3)
             Container(
                 padding :EdgeInsets.symmetric(horizontal: 20, vertical: 0),
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
          ],
        ),
      ),
    );;
  }
}
