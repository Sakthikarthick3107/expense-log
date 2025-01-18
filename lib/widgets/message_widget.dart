


import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MessageWidget{
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

  static void showToast({
      required String message,
      int? status,
      ToastGravity gravity = ToastGravity.BOTTOM,
      Toast length = Toast.LENGTH_SHORT,
      Color textColor = Colors.white,
      double fontSize = 16.0,
      int? timeInSecForIosWeb,
    }) {
        Color? backgroundColor = status == 1 ? Colors.green : status == 0 ? Colors.red : null;
        Fluttertoast.showToast(
            msg: message,
            toastLength: length,
            gravity: gravity,
            backgroundColor: backgroundColor,
            textColor: textColor,
            fontSize: fontSize,
            // timeInSecForIosWeb: timeInSecForIosWeb!
        );
  }
  static void cancelToast(){
    Fluttertoast.cancel();
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