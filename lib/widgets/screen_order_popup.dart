import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class ScreenOrderPopup extends StatefulWidget {
  final List<String> screens;
  final Function(List<String>) onSave;

  ScreenOrderPopup({required this.screens, required this.onSave});

  @override
  _ScreenOrderPopupState createState() => _ScreenOrderPopupState();
}

class _ScreenOrderPopupState extends State<ScreenOrderPopup> {
  late List<String> screenList;

  @override
  void initState() {
    super.initState();
    screenList = List.from(widget.screens);
  }

  /// Checks if the order has changed
  bool _isOrderChanged() {
    return !ListEquality().equals(screenList, widget.screens);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Reorder Screens"),
      content: SizedBox(
        width: double.maxFinite,
        child: ReorderableListView(
          shrinkWrap: true,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = screenList.removeAt(oldIndex);
              screenList.insert(newIndex, item);
            });
          },
          children: List.generate(
            screenList.length,
            (index) => ListTile(
              key: ValueKey(screenList[index]),
              title: Text(
                screenList[index],
                style: TextStyle(fontSize: 16),
              ),
              leading: Icon(
                Icons.drag_indicator,
                size: 20,
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isOrderChanged()
              ? () {
                  widget.onSave(screenList);
                  Navigator.pop(context);
                }
              : null, // Disable button if order is unchanged
          child: Text("Save"),
        ),
      ],
    );
  }
}
