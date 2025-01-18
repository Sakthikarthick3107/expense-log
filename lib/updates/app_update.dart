import 'dart:convert';
import 'dart:io';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_app_installer/flutter_app_installer.dart';
// import 'package:install_plugin/install_plugin.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:restart_app/restart_app.dart';
// import 'package:apk_installer/apk_installer.dart';

class AppUpdate{
  final String owner = 'Sakthikarthick3107';
  final String repo = 'expense-log';
  String downloadProgress = '-1';

  Future<void> downloadAndInstallApk(BuildContext context, String downloadUrl) async {
    try {
      // Request permission to access storage
      // PermissionStatus status = await Permission.storage.request();
      // if (!status.isGranted) {
      //   MessageWidget.showSnackBar(context: context,
      //       message: 'Storage permission is required',
      //       status: 0);
      //   openAppSettings();
      //   return;
      //
      // }

      // Prepare to download the APK
      final dio = Dio();
      final appDir = await getExternalStorageDirectory();
      if (appDir == null) {
        MessageWidget.showSnackBar(context: context, message: 'Could not get storage directory', status: 0);
        return;
      }
      final apkPath = '${appDir.path}/expense_log_${DateTime.now().millisecondsSinceEpoch}.apk'; // Unique file name

      // Download APK
      await dio.download(
          downloadUrl, apkPath, onReceiveProgress: (received, total) {
        if (total != -1) {
          double progress = ((received / total )* 100);
          print('Downloading ${progress}');
          EasyLoading.showProgress(progress / 100, status: 'Downloading: ${progress.toStringAsFixed(0)}%');
          // MessageWidget.showSnackBar(context: context,
          //     message: 'Downloading: ${progress.toStringAsFixed(2)}%',
          //     status: 1);
        }
      });
      EasyLoading.dismiss();
      // Check if the APK is downloaded successfully
      final file = File(apkPath);
      if (!file.existsSync()) {
        MessageWidget.showSnackBar(context: context, message: 'Failed to download APK.', status: 0);
        return;
      }

      bool installSuccess = await installApk(apkPath);

      if (installSuccess) {
        MessageWidget.showSnackBar(context: context,
            message: 'Update installed successfully!',
            status: 1);

        await Future.delayed(
            Duration(seconds: 2));
      } else {
        MessageWidget.showSnackBar(
            context: context, message: 'APK installation failed.', status: 0);
      }
    } catch (e) {
      MessageWidget.showSnackBar(context: context,
          message: 'Failed to download or install APK: $e',
          status: 0);
      print(e);
    }
  }

  Future<bool> installApk(String apkPath) async {
    const platform = MethodChannel('com.expenseapp.expense_log/install');
    try {
      final bool success = await platform.invokeMethod('installApk', {'apkPath': apkPath});
      return success;
    } on PlatformException catch (e) {
      print("Failed to install APK: ${e.message}");
      return false;
    }
  }



  Future<void> checkForUpdates(BuildContext context) async{
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');
    try{
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final response = await http.get(url);
      if(response.statusCode == 200){
        final jsonData = jsonDecode(response.body);
        final latestVersion = jsonData['tag_name'];

        final releaseNotes = jsonData['body'] ?? 'No release notes provided.';
        final downloadUrl = jsonData['assets'][0]['browser_download_url'];

        // print('Url downlpad - $downloadUrl');
        if (isNewVersion(latestVersion, currentVersion)) {
          // print('New version available: $latestVersion');
          showUpdateDialog(context, downloadUrl, releaseNotes , latestVersion);
        }
        else {
          // print('App is up-to-date!');
          // MessageWidget.showSnackBar(context: context, message: 'App is upto date', status: 1);

        }
      }
      else {
        MessageWidget.showSnackBar(context: context, message: 'Failed to fetch release', status: 0);

      }
    }
    catch(e){
      // print('Error checking for updates: $e');
      MessageWidget.showSnackBar(context: context, message: 'Error while checking updates', status: 0);
    }
  }

  bool isNewVersion(String latest, String current) {
    latest = latest.replaceFirst('v', '');
    current = current.replaceFirst('v', '');

    bool isLatestSemantic = latest.contains('.');
    bool isCurrentSemantic = current.contains('.');

    if (!isLatestSemantic && !isCurrentSemantic) {
      int latestBuild = int.parse(latest);
      int currentBuild = int.parse(current);
      return latestBuild > currentBuild;
    }

    if (isLatestSemantic && !isCurrentSemantic) {
      return true;
    }

    if (!isLatestSemantic && isCurrentSemantic) {
      return false;
    }

    List<int> latestParts = _parseVersion(latest);
    List<int> currentParts = _parseVersion(current);

    for (int i = 0; i < latestParts.length; i++) {
      int latestPart = latestParts[i];
      int currentPart = i < currentParts.length ? currentParts[i] : 0;
      if (latestPart > currentPart) {
        return true;
      } else if (latestPart < currentPart) {
        return false;
      }
    }
    return false;
  }


  List<int> _parseVersion(String version) {
    return version.split(RegExp(r'[.+]')).map(int.parse).toList();
  }

  void showUpdateDialog(BuildContext context, String downloadUrl, String releaseNotes , String latestVersion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title:const Text('Update Available'),
          content: SingleChildScrollView(
            child: ListBody(

              children: [
                Text('A new version - $latestVersion is available.\nIf you face any difficulties in updating, kindly tap on the Copy link and paste it in your browser or contact developer!'),
                const SizedBox(height: 4),
                const Text('Release Notes:'),
                Text(releaseNotes),
              InkWell(
                onTap:() {
                  _copyLinkToClipboard(context,downloadUrl);
                  Navigator.pop(context);
                }, // Call the launch function when tapped
                child:  Text(
                  'Copy link',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline, // Make it look like a link
                  ),
                ),
              ),
                const SizedBox(height: 10),
                Text(releaseNotes),
              ],
            )
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Later'),
            ),
            TextButton(
              onPressed: () async{
                Navigator.pop(context,true);
                // await _launchUrl(downloadUrl);
                downloadAndInstallApk(context , downloadUrl);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copyLinkToClipboard(BuildContext context , String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    MessageWidget.showSnackBar(context: context, message: 'Link copied to clipboard!');
  }

  Future<void> _launchUrl(String url) async {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri,
          mode: LaunchMode.externalApplication
          //   mode: LaunchMode.inAppBrowserView,
          // webViewConfiguration: const WebViewConfiguration(
          //   enableJavaScript: true, // Enable JavaScript if needed
          //   enableDomStorage: true, // Enable DOM storage for advanced web features
          // ),
        );
      } else {
        MessageWidget.showToast(message: 'Could not launch the update', status: 1);
      }

  }

}