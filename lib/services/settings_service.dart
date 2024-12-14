import 'dart:convert';

import 'package:expense_log/models/user.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

class SettingsService with ChangeNotifier{
    final _settingsBox = Hive.box('settingsBox');

    Future<User?> getUser() async{
        String userName = await _settingsBox.get('userName',defaultValue: '');
        if(userName == ''){
            return null;
        }
        User user = User(userName: userName);
        return user;

    }

    Future<void> googleSignIn() async{
        // print('Servicee g starts');
        final GoogleSignIn _googleSignIn = GoogleSignIn();
        try {
            GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

            if (googleUser != null) {
                _settingsBox.put('userName',googleUser.displayName);
                _settingsBox.put('email' ,googleUser.email);
                print('Signed in as: ${googleUser.displayName}');
                print('Email: ${googleUser.email}');
            }
        } catch (error) {
            print('Google Sign-In error: $error');
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
}