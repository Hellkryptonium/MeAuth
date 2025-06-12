import 'package:flutter/material.dart';
import '../models/auth_account.dart';

class AddAccountPage extends StatefulWidget {
  final void Function(AuthAccount) onAdd;
  const AddAccountPage({super.key, required this.onAdd});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _labelController = TextEditingController();
  final _secretController = TextEditingController();
  final _issuerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            TextField(
              controller: _secretController,
              decoration: const InputDecoration(labelText: 'Secret'),
            ),
            TextField(
              controller: _issuerController,
              decoration: const InputDecoration(labelText: 'Issuer (optional)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final acc = AuthAccount(
                  label: _labelController.text,
                  secret: _secretController.text,
                  issuer: _issuerController.text.isEmpty ? null : _issuerController.text,
                );
                widget.onAdd(acc);
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
