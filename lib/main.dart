import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/upi.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/models/message.dart' as app_message;
import 'package:expense_log/models/message.dart';
import 'package:expense_log/screens/home_screen.dart';
import 'package:expense_log/services/collection_service.dart';
import 'package:expense_log/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/report_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/services/upi_service.dart';
import 'package:expense_log/themes/app_theme.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:expense_log/utility/pdf_helper.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'background/background_task.dart';
import 'dart:async';

import 'models/collection.dart';

Future<void> requestPermissions() async {
  var status = await Permission.storage.status;

  if (!status.isGranted) {
    await Permission.storage.request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await requestPermissions();

  await Hive.initFlutter();
  // Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(ExpenseTypeAdapter());
  Hive.registerAdapter(Expense2Adapter());
  Hive.registerAdapter(CollectionAdapter());
  Hive.registerAdapter(UpiLogAdapter());
  Hive.registerAdapter(MessageAdapter());

  // await Hive.openBox<Expense>('expenseBox');
  await Hive.openBox<Expense2>('expense2Box');
  await Hive.openBox<ExpenseType>('expenseTypeBox');
  await Hive.openBox('settingsBox');
  await Hive.openBox<Collection>('collectionBox');
  await Hive.openBox<UpiLog>('upiLogBox');
  await Hive.openBox<app_message.Message>('messageBox');

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  await Workmanager()
      .registerPeriodicTask("dailyExpenseSummary", "dailyExpenseSummary",
          frequency: Duration(hours: 1),
          initialDelay: Duration(seconds: 5),
          constraints: Constraints(
            networkType: NetworkType.not_required,
          ),
          inputData: {'pass': 'Sample'});

  await Workmanager().registerPeriodicTask(
    "fetchLatest",
    "fetchLatest",
    frequency: Duration(days: 1),
    initialDelay: Duration(seconds: 10),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    inputData: {'check': 'versionUpdate'},
  );

  // await checkAndRunMigration();
  tz.initializeTimeZones(); // Initialize timezone
  await NotificationService.initialize();
  await PdfHelper.initialize();

  await FlutterDownloader.initialize(
    debug: true,
    ignoreSsl: true,
  );

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SettingsService()),
      Provider(create: (_) => UiService()),
      ProxyProvider<UiService, ExpenseService>(
        update: (_, uiService, __) => ExpenseService(uiService: uiService),
      ),
      Provider(
        create: (_) => CollectionService(),
      ),
      Provider(create: (_) => UpiService()),
      Provider(create: (_) => ReportService())
      // ProxyProvider2<ExpenseService,SettingsService,UiService>(
      //     update: (_,expenseService,settingsService,__)=> UiService(expenseService, settingsService)
      // )
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
        builder: (context, settingsService, child) {
      return MaterialApp(
        builder: EasyLoading.init(),
        title: 'ExpenseLog',
        debugShowCheckedModeBanner: false,
        theme: appTheme(
            settingsService.isDarkTheme(), settingsService.getPrimaryColor()),
        scaffoldMessengerKey: MessageWidget.scaffoldMessengerKey,
        home: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: appTheme(settingsService.isDarkTheme(),
                    settingsService.getPrimaryColor())
                .primaryColor,
            statusBarIconBrightness: settingsService.isDarkTheme()
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: settingsService.isDarkTheme()
                ? Brightness.dark
                : Brightness.light,
          ),
          child: const Scaffold(
            resizeToAvoidBottomInset: false,
            body: HomeScreen(),
          ),
        ),
      );
    });
  }
}
