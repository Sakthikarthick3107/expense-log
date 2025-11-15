import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:expense_log/models/account.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/schedule.dart';
import 'package:expense_log/models/upi.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/models/message.dart' as app_message;
import 'package:expense_log/models/message.dart';
import 'package:expense_log/screens/home_screen.dart';
import 'package:expense_log/services/accounts_service.dart';
import 'package:expense_log/services/collection_service.dart';
import 'package:expense_log/services/notification_service.dart';
import 'package:expense_log/services/schedule_service.dart';
import 'package:expense_log/services/expense_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/report_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:expense_log/services/upi_service.dart';
import 'package:expense_log/themes/app_theme.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:expense_log/services/telegram_service.dart';
import 'package:provider/provider.dart';
import 'package:expense_log/utility/pdf_helper.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';
import 'package:device_preview/device_preview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/collection.dart';

void startTelegramPolling() {
  Timer.periodic(Duration(seconds: 5), (timer) async {
    try {
      await TelegramService.checkForUpdates();
    } catch (e) {
      print('Telegram polling error: $e');
    }
  });
}

Future<void> requestPermissions() async {
  final permissions = [
    Permission.sms,
    Permission.storage,
    Permission.manageExternalStorage
  ];

  Map<Permission, PermissionStatus> statuses = await permissions.request();

  for (var entry in statuses.entries) {
    if (entry.value.isPermanentlyDenied) {
      await openAppSettings();
    }
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
  Hive.registerAdapter(AccountAdapter());
  Hive.registerAdapter(CollectionAdapter());
  Hive.registerAdapter(UpiLogAdapter());
  Hive.registerAdapter(MessageAdapter());
  Hive.registerAdapter(ScheduleAdapter());
  Hive.registerAdapter(ScheduleTypeAdapter());
  Hive.registerAdapter(RepeatOptionAdapter());
  Hive.registerAdapter(CustomByTypeAdapter());

  // await Hive.openBox<Expense>('expenseBox');
  await Hive.openBox<Expense2>('expense2Box');
  await Hive.openBox<Account>('accountsBox');
  await Hive.openBox<ExpenseType>('expenseTypeBox');
  await Hive.openBox('settingsBox');
  await Hive.openBox<Collection>('collectionBox');
  await Hive.openBox<UpiLog>('upiLogBox');
  await Hive.openBox<app_message.Message>('messageBox');
  await Hive.openBox<Schedule>('scheduleBox');

  // await Workmanager().initialize(callbackDispatcher);

  // await Workmanager().registerPeriodicTask("userschedules", "autoexpense",
  //     inputData: {}, frequency: Duration(minutes: 2));

  await AndroidAlarmManager.initialize();

  // await checkAndRunMigration();
  tz.initializeTimeZones();
  await NotificationService.initialize();
  await PdfHelper.initialize();

  await FlutterDownloader.initialize(
    debug: true,
    ignoreSsl: true,
  );
  // startTelegramPolling();
  final accountsService = AccountsService();
  await accountsService.init();
  runApp(DevicePreview(
    enabled: !kReleaseMode,
    builder: (context) => MultiProvider(
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
        Provider(create: (_) => ReportService()),
        ChangeNotifierProvider(create: (_) => ScheduleService()),
        ChangeNotifierProvider(create: (_) => accountsService),
        // ProxyProvider2<ExpenseService,SettingsService,UiService>(
        //     update: (_,expenseService,settingsService,__)=> UiService(expenseService, settingsService)
        // )
      ],
      child: const MyApp(),
    ),
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
