import 'package:flutter/material.dart';
import 'password_vault_page.dart';

class SettingsPage extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeModeNotifier;
  const SettingsPage({super.key, required this.themeModeNotifier});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text('Password Vault'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PasswordVaultPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Dark Mode'),
            trailing: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, mode, _) {
                return Switch(
                  value: mode == ThemeMode.dark,
                  onChanged: (val) {
                    themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
