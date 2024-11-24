import 'package:expense_log/migrations/hive_migrations.dart';
import 'package:expense_log/models/expense.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/screens/daily_expense_screen.dart';
import 'package:expense_log/screens/home_screen.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/themes/app_theme.dart';
import 'package:expense_log/updates/app_update.dart';
import 'package:expense_log/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

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

  runApp(
      MultiProvider(providers: [
             Provider(create: (_)=>SettingsService()),
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

      return MaterialApp(
      title: 'ExpenseLog',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      
      home:  const Scaffold(
        body: HomeScreen(),
      ),
    );
  }
}
