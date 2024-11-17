import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsService{
    final _settingsBox = Hive.box('settingsBox');

    Future<int> getBoxKey(String key) async{
        int currentId = await _settingsBox.get(key,defaultValue: 0) as int;
        int nextId = currentId + 1;
        await  _settingsBox.put(key,nextId);
        return nextId;
    }
}