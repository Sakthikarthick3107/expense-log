import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/accounts_service.dart';
import '../models/account.dart';

class AccountCreateScreen extends StatefulWidget {
  final Account? editing;
  const AccountCreateScreen({Key? key, this.editing}) : super(key: key);

  @override
  State<AccountCreateScreen> createState() => _AccountCreateScreenState();
}

class _AccountCreateScreenState extends State<AccountCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _smsKeywordCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _nameCtrl.text = widget.editing!.name;
      _codeCtrl.text = widget.editing!.code;
      _descCtrl.text = widget.editing!.description ?? '';
      _smsKeywordCtrl.text = widget.editing!.smsKeyword ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    _smsKeywordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final svc = Provider.of<AccountsService>(context, listen: false);
    try {
      if (widget.editing == null) {
        await svc.create(
                  _nameCtrl.text.trim(), 
                  _codeCtrl.text.trim(),
                  description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
                  smsSyncKeyword: _smsKeywordCtrl.text.trim());
      } else {
        final updated = widget.editing!.copyWith(
          name: _nameCtrl.text.trim(),
          code: _codeCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          smsKeyword: _smsKeywordCtrl.text.trim(),
          updatedAt: DateTime.now(),
        );
        await svc.update(updated);
      }
      Navigator.pop(context, true);
    } catch (e) {
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.editing == null ? 'Create Account' : 'Edit Account';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _codeCtrl,
              decoration: const InputDecoration(labelText: 'Code'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter code' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 2,
            ),
            TextFormField(
              controller: _smsKeywordCtrl,
              decoration: const InputDecoration(labelText: 'SMS Keyword to sync transactions'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Mandatory for sync SMS' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : (widget.editing == null ? 'Create' : 'Save')),
            ),
          ]),
        ),
      ),
    );
  }
}