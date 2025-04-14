import 'dart:convert';
import 'dart:io';
import 'package:expense_log/models/collection.dart';
import 'package:expense_log/models/expense_type.dart';
import 'package:expense_log/models/user.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../models/expense2.dart';

class SettingsService with ChangeNotifier{
    final _settingsBox = Hive.box('settingsBox');
    Map<String, dynamic> _config = {};
    Map<String,String> _themeData = {};

    Map<String, dynamic> get config => _config;
    Map<String,String> get themeData => _themeData;

    final GoogleSignIn _googleSignIn = GoogleSignIn(
        scopes: ['https://www.googleapis.com/auth/drive.file'],
    );

    Future<User?> getUser() async{
        String userName = await _settingsBox.get('userName',defaultValue: '');
        String email = await _settingsBox.get('email',defaultValue: '');
        String? image = await _settingsBox.get('image',defaultValue: '');
        if(userName == ''|| email =='' || image == ''){
            return null;
        }
        User user = User(userName: userName , email: email , image: image );
        return user;
    }

    Future<int> googleSignIn() async{
        // print('Servicee g starts');
        final GoogleSignIn _googleSignIn = GoogleSignIn();
        try {
            GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

            if (googleUser != null) {
                _settingsBox.put('userName',googleUser.displayName);
                _settingsBox.put('email' ,googleUser.email);
                _settingsBox.put('image',googleUser.photoUrl);
                print('Signed in as: ${googleUser.displayName}');
                print('Email: ${googleUser.email}');
                return 1;
            }
            return 0;
        } catch (error) {
            print('Google Sign-In error: $error');
            return 0;
        }
        return 0;
    }
    Future<String> getOrCreateFolder(drive.DriveApi driveApi, String folderName) async {
        var response = await driveApi.files.list(q: "mimeType='application/vnd.google-apps.folder' and name='$folderName'");
        if (response.files!.isNotEmpty) {
            return response.files!.first.id!; // Folder already exists
        }

        var folderMetadata = drive.File()
            ..name = folderName
            ..mimeType = "application/vnd.google-apps.folder";

        var folder = await driveApi.files.create(folderMetadata);
        return folder.id!;
    }

    Future<int> backupHiveToGoogleDrive() async {
        try {
            final account = await _googleSignIn.signIn();
            if (account == null) return 0; // Sign-in failed

            final authHeaders = await account.authHeaders;
            final authenticateClient = GoogleAuthClient(authHeaders);
            // final authenticateClient = http.Client();
            final driveApi = drive.DriveApi(authenticateClient);

            // Convert Hive data to JSON
            final directory = await getApplicationDocumentsDirectory();
            final backupFile = File('${directory.path}/hive_backup.json');

            final expense2Box = Hive.box<Expense2>('expense2Box');
            final expenseTypeBox = Hive.box<ExpenseType>('expenseTypeBox');
            final collectionBox = Hive.box<Collection>('collectionBox');
            final settingsBox = Hive.box('settingsBox');

            Map<String, dynamic> backupData = {
                "Expense2": expense2Box.values.map((e) => e.toJson()).toList(),
                "ExpenseType": expenseTypeBox.values.map((e) => e.toJson()).toList(),
                "Collection": collectionBox.values.map((e) => e.toJson()).toList(),
                "Settings": settingsBox.toMap(), // If it's a simple map, no conversion needed
            };

            await backupFile.writeAsString(jsonEncode(backupData));

            // Upload to Google Drive
            var media = drive.Media(backupFile.openRead(), backupFile.lengthSync());
            var driveFile = drive.File()..name = "expense_log_${DateTime.now().millisecondsSinceEpoch}.json";

            var uploadedFile = await driveApi.files.create(driveFile, uploadMedia: media);

            return uploadedFile.id != null ? 1 : 0; // Return 1 if successful, 0 if failed
        } catch (e) {
            print("Backup Error: $e");
            return 0; // Return 0 on error
        }
    }

    Future<int> pickBackupFileAndRestore() async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['json'], // Allow only JSON files
        );

        if (result != null) {
            File file = File(result.files.single.path!);

            try {
                String jsonString = await file.readAsString();
                Map<String, dynamic> backupData = jsonDecode(jsonString);

                // Open all required Hive boxes
                var expense2Box = Hive.box<Expense2>('expense2Box');
                var expenseTypeBox = Hive.box<ExpenseType>('expenseTypeBox');
                var collectionBox = Hive.box<Collection>('collectionBox');
                var settingsBox = Hive.box('settingsBox');

                // Clear existing data before restoring
                expense2Box.clear();
                expenseTypeBox.clear();
                collectionBox.clear();
                settingsBox.clear();

                // Restore Expense2
                if (backupData.containsKey("Expense2")) {
                    for (var entry in backupData["Expense2"]) {
                        expense2Box.put(Expense2.fromJson(entry).id,Expense2.fromJson(entry));
                    }
                }

                // Restore ExpenseType
                if (backupData.containsKey("ExpenseType")) {
                    for (var entry in backupData["ExpenseType"]) {
                        expenseTypeBox.put(ExpenseType.fromJson(entry).id,ExpenseType.fromJson(entry));
                    }
                }

                // Restore Collection
                if (backupData.containsKey("Collection")) {
                    for (var entry in backupData["Collection"]) {
                        collectionBox.put(Collection.fromJson(entry).id,Collection.fromJson(entry));
                    }
                }

                // Restore Settings (assuming it is stored as a map)
                if (backupData.containsKey("Settings")) {
                    settingsBox.putAll(backupData["Settings"]);
                }

                print("✅ Backup restored successfully!");
                return 1;
            } catch (e) {
                print("❌ Restore Error: $e");
                return 0;
            }
        } else {
            print("⚠️ No file selected");
            return 0;
        }
        return 0;
    }




    Future<int> googleSignOut() async {
        final GoogleSignIn _googleSignIn = GoogleSignIn();
        try {
            await _googleSignIn.signOut();
            _settingsBox.delete('userName');
            _settingsBox.delete('email');
            _settingsBox.delete('image');
            print('User signed out');
            return 1;
        } catch (error) {
            print('Google Sign-Out error: $error');
            return 0;
        }
    }



    Future<int> getBoxKey(String key) async{
        int currentId = await _settingsBox.get(key,defaultValue: 0) as int;
        int nextId = currentId + 1;
        await  _settingsBox.put(key,nextId);
        return nextId;
    }

    bool isDarkTheme()  {
            bool theme =  _settingsBox.get('isDarkTheme', defaultValue: false) as bool;
            return theme;
    }

    Future<void> setTheme(bool isDark) async{
        await _settingsBox.put('isDarkTheme',isDark);
        notifyListeners();
    }

    Future<String> downloadUrl(String version) async{
        final url = Uri.parse('https://api.github.com/repos/Sakthikarthick3107/expense-log/releases/tags/${version}');
        try {
            final response = await http.get(url);
            if (response.statusCode == 200) {
                final jsonData = jsonDecode(response.body);
                final downloadUrl = jsonData['assets'][0]['browser_download_url'];
                return downloadUrl;
            }
        }
        catch(e){
            print(e);
        }
        return '';
    }

    Future<int?> fetchDownloadCount() async {
        const url = 'https://api.github.com/repos/Sakthikarthick3107/expense-log/releases';
        try {
            final response = await http.get(Uri.parse(url));
            if (response.statusCode == 200) {
                final data = json.decode(response.body) as List;
                if (data.isNotEmpty) {
                    int totalDownloads = 0;

                    for (var release in data) {
                        final assets = release['assets'] as List?;
                        if (assets != null && assets.isNotEmpty) {
                            totalDownloads += assets.fold<int>(
                                0,
                                    (sum, asset) => sum + (asset['download_count'] ?? 0) as int,
                            );
                        }
                    }

                    return totalDownloads;
                }
            } else {
                // print('Failed to fetch release data: ${response.statusCode}');
                return -1;
            }
        } catch (e) {
            // print('Error fetching release data: $e');
            return -1;

        }
        return null;
    }

    List<String> getScreenOrder({bool getDefault = false}) {
        var defaultOrder = ["Expenses", "Types", "Metrics", "Collections", "UPI Logs"];

        if (getDefault) {
            return defaultOrder;
        }

        var screenOrders = _settingsBox.get('screenOrder');

        if (screenOrders != null && screenOrders is List) {
            // Fix: Ensure all items are Strings
            return screenOrders.map((e) => e.toString()).toList();
        }

        return defaultOrder;
    }

    Future<void> saveScreenOrder(List<String> updatedOrder) async{
        try{
            await _settingsBox.put('screenOrder' , updatedOrder);
            print('Saved',);
        }
        catch(e){
            print('Error while saving order');
        }
        notifyListeners();
    }

        // Future<void> loadExpenseLogTenantSettings() async{
        //     const String pat = 'LNksrAoBSUBug7bDytktALHKjphhGb5xZA';
        //     const String org = 'sakthikarthick3107';
        //     const String project = 'Sakthikarthick3107';
        //     const String repo = 'my_data_store';
        //     const String filePath = '/app-configs/expense_log_config.json';
        //
        //     final uri = Uri.https(
        //         'dev.azure.com',
        //         '/$org/$project/_apis/git/repositories/$repo/items',
        //         {
        //             'path': filePath,
        //             'includeContent': 'true',
        //             'api-version': '7.1-preview.1',
        //             r'$format': 'text',
        //         },
        //     );
        //
        //     final response = await http.get(
        //             uri,
        //             headers: {
        //                 'Authorization': 'Basic ${base64Encode(utf8.encode(':$pat'))}',
        //                 'Accept': 'application/json'
        //             },
        //         );
        //     // debugPrint('Status: ${response.statusCode}');
        //     // debugPrint('Body: ${response.body}');
        //         if (response.statusCode == 200) {
        //             _config = jsonDecode(response.body);
        //             // Primary color
        //             String tenantPrimary = _config['theme']['primary'];
        //             if (tenantPrimary != null) {
        //                 await _settingsBox.put('primary', tenantPrimary);
        //             }
        //             else {
        //                 String storedPrimary = _settingsBox.get('primary');
        //                 if (storedPrimary == null) {
        //                     storedPrimary = '#FF5722';
        //                     await _settingsBox.put('primary', storedPrimary);
        //                 }
        //             }
        //             _themeData.putIfAbsent('primary', () => _settingsBox.get('primary', defaultValue: '#FF5722'));
        //
        //             // bool tenantElevation = _config['ui']['elevation'];
        //             // if(tenantElevation != null){
        //             //     await _settingsBox.put('elevation' , tenantElevation.toString());
        //             // }
        //             // else{
        //             //     bool storedElevation = _settingsBox.get('elevation');
        //             //     if (storedElevation == null) {
        //             //         storedElevation = false;
        //             //         await _settingsBox.put('elevation', storedElevation.toString());
        //             //     }
        //             // }
        //             // _themeData.putIfAbsent('elevation', () => _settingsBox.get('elevation', defaultValue: 'false'));
        //             notifyListeners();
        //         } else {
        //             _themeData.putIfAbsent('primary', () => _settingsBox.get('primary', defaultValue: '#FF5722'));
        //             // _themeData.putIfAbsent('elevation', () => _settingsBox.get('elevation', defaultValue: 'false'));
        //             // throw Exception('Failed to fetch JSON: ${response.statusCode}');
        //         }
        // }


        Future<bool> enableElevation(bool isEnable) async{
            await _settingsBox.put('elevation', isEnable);
            notifyListeners();
            return true;
        }

    bool getElevation() {
        final dynamic storedValue = _settingsBox.get('elevation');

        if (storedValue is bool) {
            return storedValue;
        } else if (storedValue is String) {
            _settingsBox.put('elevation', storedValue.toLowerCase() == 'true');
            return storedValue.toLowerCase() == 'true' ;
        }
        return false;
    }

    String landingMetric(){
        String landingMetric = _settingsBox.get('landingMetric',defaultValue: 'This week');
        return landingMetric;
    }

    Future<bool> setLandingMetric(String duration) async{
        await _settingsBox.put('landingMetric' , duration);
        notifyListeners();
        return true;
    }

    String getPrimaryColor(){
        return _settingsBox.get('primaryColor',defaultValue: 'Blue');
    }

    Future<bool> setPrimaryColor(String color) async{
        await _settingsBox.put('primaryColor' , color);
        notifyListeners();
        return true;
    }

    String getMetricChart(){
        String metricChart = _settingsBox.get('metricChart',defaultValue: 'Bar Chart');
        return metricChart;
    }

    Future<bool> setMetricChart(String chart) async{
        await _settingsBox.put('metricChart' , chart);
        notifyListeners();
        return true;
    }


}

class GoogleAuthClient extends http.BaseClient {
    final Map<String, String> _headers;  // Stores authentication headers
    final http.Client _client = http.Client();  // Creates a standard HTTP client

    GoogleAuthClient(this._headers);  // Constructor receives headers

    @override
    Future<http.StreamedResponse> send(http.BaseRequest request) {
        return _client.send(request..headers.addAll(_headers));
        // Adds authentication headers to every request
    }
}
