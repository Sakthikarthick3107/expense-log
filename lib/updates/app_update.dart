import 'dart:convert';

import 'package:expense_log/widgets/message_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AppUpdate{
  final String owner = 'Sakthikarthick3107';
  final String repo = 'expense-log';

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
        print('Url downlpad - $downloadUrl');
        if (isNewVersion(latestVersion, currentVersion)) {
          print('New version available: $latestVersion');
          showUpdateDialog(context, downloadUrl, releaseNotes);
        }
        else {
          print('App is up-to-date!');
          MessageWidget.showSnackBar(context: context, message: 'App is upto date', status: 1);

        }
      }
      else {
        MessageWidget.showSnackBar(context: context, message: 'Failed to fetch release', status: 0);

      }
    }
    catch(e){
      print('Error checking for updates: $e');
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

  void showUpdateDialog(BuildContext context, String downloadUrl, String releaseNotes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title:const Text('Update Available'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                const Text('A new version of the app is available.'),
                const SizedBox(height: 4),
                const Text('Release Notes:'),
                const SizedBox(height: 10),
                Text(releaseNotes),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Later'),
            ),
            TextButton(
              onPressed: () async{
                Navigator.pop(context);
                await _launchUrl(downloadUrl);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        MessageWidget.showToast(message: 'Could not launch the update', status: 1);
      }

  }

}