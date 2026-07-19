import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MessageWidget {
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
    Color bgColor;

    switch (status) {
      case 1:
        bgColor = const Color(0xFF2E7D32);
        break;
      case 0:
        bgColor = const Color(0xFFC62828);
        break;
      default:
        bgColor = const Color(0xFF1565C0);
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: length,
      gravity: gravity,
      textColor: Colors.white,
      fontSize: fontSize,
      backgroundColor: bgColor,
      timeInSecForIosWeb: timeInSecForIosWeb ?? 1,
    );
  }

  static void showSnackBar({
    required BuildContext context,
    required String message,
    int? status,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    Duration duration = const Duration(seconds: 4),
    double fontSize = 16.0,
  }) {
    Color? iconColor;
    IconData? iconData;

    switch (status) {
      case 1:
        iconData = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case 0:
        iconData = Icons.error_outline;
        iconColor = Colors.red;
        break;
      case -1:
        iconData = Icons.info_outline;
        iconColor = Colors.orangeAccent;
        break;
    }

    final snackBar = SnackBar(
      content: Row(
        children: [
          if (iconData != null) ...[
            Icon(iconData, color: iconColor, size: 22),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: fontSize),
            ),
          ),
        ],
      ),
      duration: duration,
      behavior: behavior,
      margin: const EdgeInsets.all(12),
    );
    scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }
}
