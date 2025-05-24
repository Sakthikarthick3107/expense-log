import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InfoDialog extends StatelessWidget {
  final String title;
  final List<Widget> content;
  final VoidCallback? onClosed;

  const InfoDialog({
    Key? key,
    this.title = 'Information',
    required this.content,
    this.onClosed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: content,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onClosed != null) {
              onClosed!();
            }
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  static Future<void> showInfo({
    required BuildContext context,
    String? title,
    required List<Widget> content,
    VoidCallback? onClosed,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => InfoDialog(
        title: title ?? 'Information',
        content: content,
        onClosed: onClosed,
      ),
    );
  }
}
