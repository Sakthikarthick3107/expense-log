import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:expense_log/models/expense2.dart';
import 'package:expense_log/models/schedule.dart';
import 'package:expense_log/models/upi.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/models/message.dart' as app_message;
import 'package:expense_log/models/message.dart';
import 'package:expense_log/screens/home_screen.dart';
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
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

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

Future<void> disableBatteryOptimizations() async {
  try {
    const package = "com.expenseapp.expense_log";
    final androidInfo = await DeviceInfoPlugin().androidInfo;

    // For Android 6-9 (API 23-28)
    if (androidInfo.version.sdkInt <= 28) {
      final intent = AndroidIntent(
        action: "android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS",
        data: "package:$package",
      );
      await intent.launch();
    }
    // For Android 10+ and OEM devices
    else {
      await _openManufacturerSpecificSettings();
    }
  } catch (e) {
    print('Failed to open battery optimization settings: $e');
    await openAppSettings(); // Fallback
  }
}

Future<void> _openManufacturerSpecificSettings() async {
  const package =
      "com.expenseapp.expense_log"; // REPLACE WITH YOUR ACTUAL PACKAGE NAME
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  final manufacturer = androidInfo.manufacturer.toLowerCase();

  try {
    if (manufacturer.contains('xiaomi') || manufacturer.contains('redmi')) {
      await AndroidIntent(
        action: "miui.intent.action.APP_AUTOSTART_MANAGE",
        data: "package:$package",
      ).launch();
    } else if (manufacturer.contains('huawei')) {
      await AndroidIntent(
        action: "com.huawei.systemmanager",
        data: "package:$package",
      ).launch();
    } else if (manufacturer.contains('oppo')) {
      await AndroidIntent(
        action: "com.oppo.safe",
        data: "package:$package",
      ).launch();
    } else {
      await openAppSettings();
    }
  } catch (e) {
    await openAppSettings();
  }
}

Future<void> requestPermissions() async {
  final permissions = [
    Permission.sms,
    Permission.storage,
    Permission.manageExternalStorage,
    // Permission.scheduleExactAlarm
  ];

  Map<Permission, PermissionStatus> statuses = await permissions.request();

  for (var entry in statuses.entries) {
    if (entry.value.isPermanentlyDenied) {
      await openAppSettings();
    }
  }
}

Future<void> checkAndRequestExactAlarmPermission() async {
  var status = await Permission.scheduleExactAlarm.status;

  if (status.isDenied || status.isRestricted) {
    bool opened = await openAppSettings();
    if (!opened) {
      print(
          'Please open app settings and enable Schedule Exact Alarm permission.');
    }
  } else if (status.isPermanentlyDenied) {
    await openAppSettings();
  } else {
    print('Schedule Exact Alarm permission already granted.');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await requestPermissions();
  // await disableBatteryOptimizations();
  // await checkAndRequestExactAlarmPermission();

  await Hive.initFlutter();
  // Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(ExpenseTypeAdapter());
  Hive.registerAdapter(Expense2Adapter());
  Hive.registerAdapter(CollectionAdapter());
  Hive.registerAdapter(UpiLogAdapter());
  Hive.registerAdapter(MessageAdapter());
  Hive.registerAdapter(ScheduleAdapter());
  Hive.registerAdapter(ScheduleTypeAdapter());
  Hive.registerAdapter(RepeatOptionAdapter());

  // await Hive.openBox<Expense>('expenseBox');
  await Hive.openBox<Expense2>('expense2Box');
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
  tz.initializeTimeZones(); // Initialize timezone
  await NotificationService.initialize();
  await PdfHelper.initialize();

  await FlutterDownloader.initialize(
    debug: true,
    ignoreSsl: true,
  );
  // startTelegramPolling();
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
        ChangeNotifierProvider(create: (_) => ScheduleService())
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
