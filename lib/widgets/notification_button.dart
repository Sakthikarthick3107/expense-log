import 'package:expense_log/screens/message_screen.dart';
import 'package:flutter/material.dart';

class NotificationButton extends StatelessWidget {
  final int unreadCount;

  const NotificationButton({Key? key, required this.unreadCount})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // To prevent the red circle from getting clipped
      children: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MessageScreen()),
            );
          },
          icon: Icon(Icons.notifications_on_outlined),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
