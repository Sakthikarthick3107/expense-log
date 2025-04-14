


import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MessageWidget{
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

  static void showToast({
    required BuildContext context,
    required String message,
    int? status,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Toast length = Toast.LENGTH_LONG,
    double fontSize = 16.0,
    int? timeInSecForIosWeb,
  }) {

    String icon = status == 1
        ? '✅ '
        : status == 0
        ? '❌ '
        : 'ℹ️ ';

    Fluttertoast.showToast(
      msg: '$icon $message',
      toastLength: length,
      gravity: gravity,
      textColor:  Theme.of(context).scaffoldBackgroundColor,
      fontSize: fontSize,
      // timeInSecForIosWeb: timeInSecForIosWeb,
      backgroundColor:Theme.of(context).textTheme.displayMedium?.color
    );
  }

  static void showSnackBar({
    required BuildContext context,
    required String message,
    int? status,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    Duration duration = const Duration(seconds: 4),

    double fontSize = 16.0
  }){
    Icon? statusIcon = status == 1 ? Icon(Icons.sentiment_satisfied_alt_outlined , color: Colors.green,) :
                      status == 0 ? Icon(Icons.sms_failed_outlined , color: Colors.red,) :
                      status == -1 ? Icon(Icons.info , color: Colors.deepOrangeAccent,) :null;
      final snackBar = SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  message,
                style: TextStyle(
                  fontSize: fontSize
                ),
              ),
              if(statusIcon != null)
                statusIcon,
            ],
          ),
          duration: duration,
          behavior: behavior,
      );
      scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }
}