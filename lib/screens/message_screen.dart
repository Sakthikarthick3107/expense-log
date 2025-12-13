import 'package:expense_log/services/settings_service.dart';
import 'package:expense_log/services/ui_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_log/models/message.dart'
    as app_model; // To avoid ambiguity

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<UiService>(
      builder: (context, uiService, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Messages'),
          ),
          body:
              Consumer<SettingsService>(builder: (context, settingsService, _) {
            final messages = settingsService.getMessages();
            if (messages.isEmpty) {
              return Center(
                child: Text('No messages yet.'),
              );
            }
            return ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final app_model.Message msg = messages[index];
                return ListTile(
                  tileColor: msg.isRead
                      ? Colors.transparent
                      : Theme.of(context).primaryColor,
                  onTap: () {
                    msg.markAsRead();
                    settingsService.readMessage(msg);
                    setState(() {});
                  },
                  title: Text(
                    msg.content,
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    msg.title,
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    uiService.displayMessageTime(msg.date),
                    style: TextStyle(fontSize: 10),
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }
}
