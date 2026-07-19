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
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                      ),
                      child: Icon(Icons.groups, size: 48, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No groups yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a group to split expenses\nwith friends and family',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final memberCount = group.members.length;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      group.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    group.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(Icons.people_outline, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text('$memberCount members',
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
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
                    icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit_outlined, size: 20), title: Text('Edit'), dense: true),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(leading: Icon(Icons.delete_outline, size: 20, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)), dense: true),
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
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (_) => const GroupForm(),
          );
          if (result == true) setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
      ),
    );
  }
}
