import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/updates/app_update.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
          style: TextStyle(
            color: Colors.white
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              onTap: (){
                setState(() {
                  settingIndex = settingIndex == 1 ? 0 : 1;
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
                  settingIndex = settingIndex == 2 ? 0 : 2;
                });
              },
              title: Text('Theme'),
            ),
            if(settingIndex == 2)
              Consumer<SettingsService>(
                builder: (context , settingsService,child){

                    return Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 40, vertical: 0),
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
                  settingIndex = settingIndex ==3 ? 0 : 3;
                });
                final appUpdate = AppUpdate();
                appUpdate.checkForUpdates(context);
              },
              title: Text('Updates'),
            ),
            if(settingIndex == 3)
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
              ),
            ListTile(
              onTap: (){
                setState(() {
                  settingIndex = settingIndex ==4 ? 0 : 4;
                });
              },
              title: Text('Developer Info'),
            ),
            if(settingIndex == 4)
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
          ],
        ),
      ),
    );;
  }
}
