import 'package:expense_log/models/group.dart';
import 'package:expense_log/services/group_service.dart';
import 'package:expense_log/screens/group_detail_screen.dart';
import 'package:expense_log/widgets/group_form.dart';
import 'package:expense_log/widgets/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Group>('groupsBox').listenable(),
        builder: (context, Box<Group> box, _) {
          final groups = Provider.of<GroupService>(context, listen: false).getGroups();
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No groups yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to create a group',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final memberCount = group.members.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).cardColor,
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: CircleAvatar(
                      radius: 16,
                      child: Text(
                        group.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      group.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('$memberCount members',
                        style: const TextStyle(fontSize: 12)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (_) => GroupForm(group: group),
                          );
                          if (result == true) setState(() {});
                        } else if (value == 'delete') {
                          WarningDialog.showWarning(
                            context: context,
                            title: 'Delete Group',
                            message:
                                'Are you sure you want to delete "${group.name}"?',
                            onConfirmed: () {
                              Provider.of<GroupService>(context, listen: false)
                                  .deleteGroup(group.id);
                              setState(() {});
                            },
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupDetailScreen(group: group),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (_) => const GroupForm(),
          );
          if (result == true) setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
