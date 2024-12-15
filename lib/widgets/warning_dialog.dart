import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WarningDialog extends StatelessWidget {
  final VoidCallback onConfirmed;
  final String title;
  final String message;
  final VoidCallback? onCancelled;

  const WarningDialog({
    Key? key,
    required this.onConfirmed,
    this.title = 'Warning',
    this.message = 'Are you sure you want to proceed?',
    this.onCancelled
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            if (onCancelled != null) {
              onCancelled!();
            } else {
              Navigator.of(context).pop();
            }
          },
          child: const Text('No'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirmed();
          },
          child: const Text('Yes'),
        ),
      ],
    );
  }

  // Static method to show the dialog
  static Future<void> showWarning({
    required BuildContext context,
    String? title,
    String? message,
    required VoidCallback onConfirmed,
    VoidCallback? onCancelled
  }) async {
    showDialog(
      context: context,
      builder: (context) {
        return WarningDialog(
          title: title ?? 'Warning',
          message: message ?? 'Are you sure you want to proceed?',
          onConfirmed: onConfirmed,
          onCancelled : onCancelled
        );
      },
    );
  }
}