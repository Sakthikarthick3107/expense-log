


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
    Color textColor = Colors.white,
    double fontSize = 16.0
  }){
    Color? backgroundColor = status == 1 ? Colors.green : status == 0 ? Colors.red : null;
      final snackBar = SnackBar(
          content: Text(
              message,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize
            ),
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: behavior,
      );
      scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }
}