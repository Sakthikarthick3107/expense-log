import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accounts_service.dart';
import '../models/account.dart';
import 'account_create_screen.dart';
import 'account_view_screen.dart';

class AccountsListScreen extends StatelessWidget {
  const AccountsListScreen({Key? key}) : super(key: key);

  Future<void> _openCreate(BuildContext ctx) async {
    final res = await Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AccountCreateScreen()));
    if (res == true) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Account saved')));
  }

  @override
  Widget build(BuildContext context) {
    final svc = Provider.of<AccountsService>(context);
    final accounts = svc.all;
    return Scaffold(
      appBar: AppBar(toolbarHeight: 35,title: const Text('Accounts')),
      body: accounts.isEmpty
          ? const Center(child: Text('No accounts yet. Tap + to add one.'))
          : ListView.separated(
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final a = accounts[i];
                return ListTile(
                  title: Text(a.name),
                  subtitle: Text(a.code + (a.description != null && a.description!.isNotEmpty ? ' • ${a.description}' : '')),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => AccountCreateScreen(editing: a)));
                        if (res == true) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account updated')));
                      },
                    ),
                    // IconButton(
                    //   icon: const Icon(Icons.delete),
                    //   onPressed: () async {
                    //     final ok = await showDialog<bool>(
                    //           context: context,
                    //           builder: (_) => AlertDialog(
                    //             title: const Text('Delete account'),
                    //             content: Text('Delete account "${a.name}"? This cannot be undone.'),
                    //             actions: [
                    //               TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    //               ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    //             ],
                    //           ),
                    //         ) ??
                    //         false;
                    //     if (ok) {
                    //       await svc.delete(a.id);
                    //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted')));
                    //     }
                    //   },
                    // ),
                  ]),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccountViewScreen(account: a))),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openCreate(context), child: const Icon(Icons.add)),
    );
  }
}