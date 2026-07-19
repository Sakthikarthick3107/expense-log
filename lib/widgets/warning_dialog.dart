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
      title: Row(children: [
        Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
        const SizedBox(width: 10),
        Expanded(child: Text(title)),
      ]),
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirmed();
          },
          child: const Text('Confirm'),
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