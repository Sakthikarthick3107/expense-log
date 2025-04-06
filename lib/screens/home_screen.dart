import 'dart:io';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/models/user.dart';
import 'package:expense_log/screens/collections_screen.dart';
import 'package:expense_log/screens/daily_expense_screen.dart';
import 'package:expense_log/screens/expense_type_screen.dart';
import 'package:expense_log/screens/metrics_screen.dart';
import 'package:expense_log/screens/settings_screen.dart';
import 'package:expense_log/screens/upi_logs.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/notification_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/services/upi_service.dart';
import 'package:expense_log/updates/app_update.dart';
import 'package:expense_log/widgets/app_drawer.dart';
import 'package:expense_log/widgets/avatar_widget.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:expense_log/widgets/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String version = '';
  int _currentIndex = 0;
  User? user;
  late SettingsService _settingsService;
  late ExpenseService _expenseService;
  late UiService _uiService;
  late List<Widget> orderScreens = [];
  static const platform = MethodChannel('com.expenseapp.expense_log/install');
  late UpiService _upiService;



  @override
  void initState() {
    super.initState();
    _requestPermissions();
    // _listenForSms();

    setState(() {
      _currentIndex = widget.initialIndex;
    });
    _settingsService = Provider.of<SettingsService>(context,listen: false);
    _uiService = Provider.of<UiService>(context,listen: false);
    _expenseService = Provider.of<ExpenseService>(context , listen: false);
    _checkIfUserExists();
    _scheduleNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appUpdate = AppUpdate();
      appUpdate.checkForUpdates(context);
      welcomeGreeting();
      reorderScreens();
    });
    _fetchVersion();
    _upiService = Provider.of<UpiService>(context , listen: false);
  }


  Future<void> _requestPermissions() async {
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      await Permission.sms.request();
    }
  }

  // Future<void> _listenForSms() async {
  //   platform.setMethodCallHandler((call) async {
  //     UpiService upiService = UpiService();
  //     if (call.method == "onSmsReceived") {
  //       String message = call.arguments;
  //       upiService.createLog(message);
  //       print("📩 SMS Received in Flutter: $message");
  //     }
  //   });
  // }




  final List<Widget> _screens = [
    const DailyExpenseScreen(),
    const ExpenseTypeScreen(),
    const MetricsScreen(),
    const CollectionsScreen(),
    const UpiLogs(),
    const SettingsScreen()
  ];

  Future<void> reorderScreens() async{
    List<String> savedOrder = await _settingsService.getScreenOrder();
    List<String> defaultOrder = await _settingsService.getScreenOrder(getDefault: true);
    List<Widget> orderedScreens = [];

    for (String screen in savedOrder) {
      int index = defaultOrder.indexOf(screen);
      if (index != -1) {
          orderedScreens.add(_screens[index]);

      }
    }
      orderedScreens.add(_screens.last);

    setState(() {
      orderScreens = orderedScreens;
    });
  }

  Future<void> _fetchVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
    });
  }



  Future<void> _scheduleNotifications() async{
    final _settingsBox = Hive.box('settingsBox');
    String userName = await _settingsBox.get('userName',defaultValue: 'User');
    NotificationService.scheduleNotification(
      id: 1,
      title: 'Good Morning, $userName!',
      body: 'Start your day with your favourite activity.',
      hour: 5,
      minute: 0,
    );

    NotificationService.scheduleNotification(
      id: 2,
      title: 'Morning Reminder, $userName!',
      body: 'Have a check whether you missed any expenses?',
      hour: 7,
      minute: 0,
    );

    NotificationService.scheduleNotification(
      id: 3,
      title: 'Good Morning Reminder, $userName!',
      body: 'Did you forget to add your meals expenses?',
      hour: 9,
      minute: 0,
    );

    NotificationService.scheduleNotification(
      id: 4,
      title: 'Good Afternoon, $userName!',
      body: 'Did you track your afternoon expenses?',
      hour: 11,
      minute: 0,
    );

    NotificationService.scheduleNotification(
      id: 5,
      title: 'Good Afternoon Reminder, $userName!',
      body: 'Don\'t forget to track after having your snacks.',
      hour: 13,
      minute: 0,
    );

    NotificationService.scheduleNotification(
      id: 6,
      title: 'Good Evening, $userName!',
      body: 'Remember to track your evening expenses.',
      hour: 15,
      minute: 0,
    );

    NotificationService.scheduleNotification(
      id: 7,
      title: 'Good Evening Reminder, $userName!',
      body: 'Don’t forget to add any late afternoon expenses.',
      hour: 17,
      minute: 0,
    );

    NotificationService.scheduleNotification(
      id: 8,
      title: 'Late Evening Reminder, $userName!',
      body: 'Check if you have tracked all your expenses today.',
      hour: 19,
      minute: 0,
    );

    NotificationService.scheduleNotification(
      id: 9,
      title: 'Night Reminder, $userName!',
      body: 'Almost time to wrap up your expenses for the day.',
      hour: 21,
      minute: 0,
    );

    NotificationService.scheduleNotification(
      id: 10,
      title: 'Good Night, $userName!',
      body: 'Make sure you have added all your expenses for today.',
      hour: 23,
      minute: 0,
    );

  }

  Future<void> _checkIfUserExists() async{
    User? userData = await _settingsService.getUser();
    setState(() {
      user = userData;
    });
  }

  void welcomeGreeting(){
    String timeOfDay = _uiService.getTimeOfDay();
    String userName = user != null ? user!.userName : 'User';
    MessageWidget.showSnackBar(context: context, message: 'Good $timeOfDay, $userName' , status: -1);
  }



  void _onDrawerItemSelected(int index){
    if(!Platform.isWindows)
    Navigator.pop(context);
    setState(() {
      _currentIndex = index;
    });

  }

  @override
  Widget build(BuildContext context){
    return WillPopScope(
      onWillPop: ()async{
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false;
        }
        bool willExit = false;
        await WarningDialog.showWarning(
          context: context,
          message: 'Are you sure to exit app?',
          onConfirmed: () {
            willExit =  true;
            SystemNavigator.pop(animated: true);
          }

        );
        return willExit;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        drawer:Platform.isWindows ? null : AppDrawer(onSelectScreen: _onDrawerItemSelected),
          appBar:  AppBar(
              title:  Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 0,
                children: [
                  Text(
                    'expense.log',
                    style:const TextStyle(
                        fontWeight: FontWeight.bold,
                      fontSize: 22
                    ),
            
                  ),
               if(orderScreens[_currentIndex].runtimeType == DailyExpenseScreen)
               Text(
                   'This month : ₹ ${_expenseService.getMetrics('This month','By type',[])['Total']?.toStringAsFixed(2)}',
                 style: TextStyle(
                   fontSize: 12
                 ),

               )
                ],
              ),
              actions: [
                if(user == null)
                Container(
                  padding: EdgeInsets.all(10),
                  // margin: EdgeInsets.all(20),
                  child: Text(
                    '$version',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12
                    ),
                  ),
                ),
                if(user != null)
                Container(
                  padding: EdgeInsets.all(6),
                  child: AvatarWidget(
                    imageUrl: user!.image,
                    userName: user!.userName,
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
                    },
                  )
                )
              ],
              //leading: Text(version),
            ),

        body: Platform.isWindows ?
              Container(
                child: Row(
                  children: [
                    AppDrawer(onSelectScreen: _onDrawerItemSelected),
                    Expanded(child: orderScreens[_currentIndex])
                  ],
                ),
              )
            :  orderScreens[_currentIndex],
      ),
    );
  }
}
