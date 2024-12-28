import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/screens/home_screen.dart';
import 'package:expense_log/services/notification_service.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/themes/app_theme.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> requestPermissions() async {
  var status = await Permission.storage.status;

  if (!status.isGranted) {
    await Permission.storage.request();
  }
}


void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await requestPermissions();

  await Hive.initFlutter();
  // Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(ExpenseTypeAdapter());
  Hive.registerAdapter(Expense2Adapter());

  // await Hive.openBox<Expense>('expenseBox');
  await Hive.openBox<Expense2>('expense2Box');
  await Hive.openBox<ExpenseType>('expenseTypeBox');
  await Hive.openBox('settingsBox');

  // await checkAndRunMigration();
  tz.initializeTimeZones(); // Initialize timezone
  await NotificationService.initialize();

  runApp(
      MultiProvider(providers: [
             ChangeNotifierProvider(create: (_)=>SettingsService()),
              Provider(create: (_)=>ExpenseService()),
              Provider(create: (_) => UiService()),
              // ProxyProvider2<ExpenseService,SettingsService,UiService>(
              //     update: (_,expenseService,settingsService,__)=> UiService(expenseService, settingsService)
              // )
      ],
        child: const MyApp(),
      )
      );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
      return Consumer<SettingsService>(
          builder: (context,settingsService,child){
            return MaterialApp(
              builder: EasyLoading.init(),
              title: 'ExpenseLog',
              debugShowCheckedModeBanner: false,
              theme: appTheme(settingsService.isDarkTheme()),
              scaffoldMessengerKey: MessageWidget.scaffoldMessengerKey,
              home:  const Scaffold(
                body: HomeScreen(),
              ),
            );
          });

  }
}
