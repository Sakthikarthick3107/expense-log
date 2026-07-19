import 'package:expense_log/models/group.dart';
import 'package:expense_log/services/group_service.dart';
import 'package:expense_log/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GroupForm extends StatefulWidget {
  final Group? group;

  const GroupForm({super.key, this.group});

  @override
  State<GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends State<GroupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late List<String> _members;
  final _newMemberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _members = widget.group != null
        ? List.from(widget.group!.members)
        : ['Me'];
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _descriptionController.text = widget.group!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _newMemberController.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _newMemberController.text.trim();
    if (name.isNotEmpty && !_members.contains(name)) {
      setState(() {
        _members.add(name);
        _newMemberController.clear();
      });
    }
  }

  void _removeMember(String member) {
    if (member == 'Me') return;
    setState(() {
      _members.remove(member);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.group != null ? 'Edit Group' : 'New Group'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Group name is mandatory' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _newMemberController,
                      decoration: const InputDecoration(
                        labelText: 'Add Member',
                        hintText: 'Enter name',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _addMember,
                    icon: const Icon(Icons.add_circle),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_members.isEmpty)
                const Text('No members. Add at least one member.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _members.map((member) {
                    return Chip(
                      label: Text(member),
                      deleteIcon:
                          member == 'Me' ? null : const Icon(Icons.close, size: 18),
                      onDeleted: member == 'Me'
                          ? null
                          : () => _removeMember(member),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              if (_members.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add at least one member')),
                );
                return;
              }
              final settingsService =
                  Provider.of<SettingsService>(context, listen: false);
              final groupService =
                  Provider.of<GroupService>(context, listen: false);
              final group = Group(
                id: widget.group?.id ??
                    await settingsService.getBoxKey('groupsBox'),
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                created: widget.group?.created ?? DateTime.now(),
                updated: widget.group != null ? DateTime.now() : null,
                members: _members,
              );
              final result = await groupService.createGroup(group);
              if (result == 1) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group name already exists')),
                );
              }
            }
          },
          child: Text(widget.group != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
