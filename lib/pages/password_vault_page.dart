import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/vault_entry.dart';
import '../services/vault_master_password_service.dart';
import '../services/vault_storage_service.dart';
import '../services/vault_crypto_service.dart';
import '../services/key_derivation_service.dart';

class PasswordVaultPage extends StatefulWidget {
  const PasswordVaultPage({super.key});

  @override
  State<PasswordVaultPage> createState() => _PasswordVaultPageState();
}

class _PasswordVaultPageState extends State<PasswordVaultPage> {
  bool _unlocked = false;
  bool _loading = true;
  String? _error;
  List<VaultEntry> _entries = [];
  String? _masterPassword;
  List<int>? _encryptionKey;

  final _masterService = VaultMasterPasswordService();
  final _storageService = VaultStorageService();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkVault();
  }

  Future<void> _checkVault() async {
    setState(() => _loading = true);
    final isSet = await _masterService.isMasterPasswordSet();
    setState(() {
      _loading = false;
      _unlocked = false;
      _error = null;
    });
    if (!isSet) {
      _showSetMasterPasswordDialog();
    } else {
      _showUnlockDialog();
    }
  }

  Future<List<int>?> _getVaultSalt() async {
    final saltHex = await _masterService.getSaltHex();
    if (saltHex == null) return null;
    return KeyDerivationService.saltFromHex(saltHex);
  }

  Future<void> _showSetMasterPasswordDialog() async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    String? localError;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Set Master Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Master Password'),
                  ),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                  ),
                  if (localError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(localError!, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (controller.text.isEmpty || controller.text != confirmController.text) {
                      setStateDialog(() {
                        localError = 'Passwords do not match.';
                      });
                      return;
                    }
                    await _masterService.setMasterPassword(controller.text);
                    setState(() {
                      _masterPassword = controller.text;
                    });
                    Navigator.pop(context);
                    _unlockWithPassword(controller.text);
                  },
                  child: const Text('Set'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showUnlockDialog() async {
    final controller = TextEditingController();
    final LocalAuthentication auth = LocalAuthentication();
    bool canCheckBiometrics = await auth.canCheckBiometrics;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Unlock Vault'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Master Password'),
                  ),
                  if (canCheckBiometrics)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Unlock with Biometrics'),
                        onPressed: () async {
                          try {
                            bool didAuth = await auth.authenticate(
                              localizedReason: 'Unlock your password vault',
                            );
                            if (didAuth) {
                              // After biometrics, try to unlock with entered password
                              if (controller.text.isNotEmpty) {
                                Navigator.pop(context);
                                _unlockWithPassword(controller.text);
                              } else {
                                setStateDialog(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Enter your master password after biometrics.')),
                                );
                              }
                            }
                          } catch (_) {}
                        },
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    _unlockWithPassword(controller.text);
                  },
                  child: const Text('Unlock'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _unlockWithPassword(String password) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(Duration.zero); // Allow loading spinner to show
    final ok = await _masterService.verifyMasterPassword(password);
    if (!ok) {
      setState(() {
        _loading = false;
        _error = 'Incorrect master password.';
      });
      _showUnlockDialog();
      return;
    }
    // Derive encryption key on main thread
    final salt = await _getVaultSalt();
    if (salt == null) {
      setState(() {
        _loading = false;
        _error = 'Vault salt missing.';
      });
      return;
    }
    final key = await KeyDerivationService.deriveKey(password, salt);
    setState(() {
      _unlocked = true;
      _loading = false;
      _masterPassword = password;
      _encryptionKey = key;
    });
    await _loadVaultEntries(key);
  }

  Future<void> _loadVaultEntries(List<int> key) async {
    final encrypted = await _storageService.loadEncryptedVault();
    if (encrypted == null) {
      setState(() => _entries = []);
      return;
    }
    try {
      setState(() => _loading = true);
      await Future.delayed(Duration.zero); // Allow loading spinner to show
      final decrypted = VaultCryptoService.decryptVault(encrypted, key);
      final List<dynamic> data = json.decode(decrypted);
      final entries = data.map((e) => VaultEntry.fromJson(e)).toList();
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to decrypt vault.';
        _entries = [];
        _loading = false;
      });
    }
  }

  Future<void> _saveVaultEntries(List<VaultEntry> entries) async {
    if (_encryptionKey == null) return;
    final jsonStr = json.encode(entries.map((e) => e.toJson()).toList());
    final encrypted = VaultCryptoService.encryptVault(jsonStr, _encryptionKey!);
    await _storageService.saveEncryptedVault(encrypted);
    setState(() {
      _entries = entries;
    });
  }

  Future<void> _showAddPasswordDialog() async {
    final appController = TextEditingController();
    final userController = TextEditingController();
    final passController = TextEditingController();
    String selectedIcon = '';
    int selectedIconIndex = -1;
    final List<String> icons = ['🔑','📱','💻','🌐','📧','🔒','🛡️','⭐','🏦','💼','🎮','📷','🎵','🛒','🏠','💳','🧑‍💻','👤','📚','⚙️'];
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: appController,
                      decoration: const InputDecoration(labelText: 'App/Site Name'),
                    ),
                    TextField(
                      controller: userController,
                      decoration: const InputDecoration(labelText: 'Username/Email'),
                    ),
                    TextField(
                      controller: passController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    // Icon picker (emoji)
                    Wrap(
                      spacing: 6,
                      children: [
                        ...List.generate(icons.length, (i) => GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              selectedIcon = icons[i];
                              selectedIconIndex = i;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: selectedIconIndex == i ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(icons[i], style: const TextStyle(fontSize: 22)),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (appController.text.isEmpty || userController.text.isEmpty || passController.text.isEmpty) return;
                    final entry = VaultEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      appName: appController.text,
                      username: userController.text,
                      password: passController.text,
                      icon: selectedIcon,
                    );
                    final updated = List<VaultEntry>.from(_entries)..add(entry);
                    await _saveVaultEntries(updated);
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditPasswordDialog(VaultEntry entry, int idx) async {
    final appController = TextEditingController(text: entry.appName);
    final userController = TextEditingController(text: entry.username);
    final passController = TextEditingController(text: entry.password);
    String selectedIcon = entry.icon;
    int selectedIconIndex = -1;
    final List<String> icons = ['🔑','📱','💻','🌐','📧','🔒','🛡️','⭐','🏦','💼','🎮','📷','🎵','🛒','🏠','💳','🧑‍💻','👤','📚','⚙️'];
    if (selectedIcon.isNotEmpty) {
      selectedIconIndex = icons.indexOf(selectedIcon);
    }
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: appController,
                      decoration: const InputDecoration(labelText: 'App/Site Name'),
                    ),
                    TextField(
                      controller: userController,
                      decoration: const InputDecoration(labelText: 'Username/Email'),
                    ),
                    TextField(
                      controller: passController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        ...List.generate(icons.length, (i) => GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              selectedIcon = icons[i];
                              selectedIconIndex = i;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: selectedIconIndex == i ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(icons[i], style: const TextStyle(fontSize: 22)),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (appController.text.isEmpty || userController.text.isEmpty || passController.text.isEmpty) return;
                    final updatedEntry = VaultEntry(
                      id: entry.id,
                      appName: appController.text,
                      username: userController.text,
                      password: passController.text,
                      icon: selectedIcon,
                    );
                    final updated = List<VaultEntry>.from(_entries);
                    updated[idx] = updatedEntry;
                    await _saveVaultEntries(updated);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEntryOptions(VaultEntry entry, int idx) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        );
      },
    );
    if (result == 'edit') {
      _showEditPasswordDialog(entry, idx);
    } else if (result == 'delete') {
      final updated = List<VaultEntry>.from(_entries)..removeAt(idx);
      await _saveVaultEntries(updated);
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password copied to clipboard (auto-clears in 30s)')),
    );
    Future.delayed(const Duration(seconds: 30), () async {
      final data = await Clipboard.getData('text/plain');
      if (data != null && data.text == text) {
        // Only clear if clipboard is unchanged
        await Clipboard.setData(const ClipboardData(text: ''));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard cleared')), // Optional: feedback
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Password Vault')),
        body: Center(
          child: _error != null ? Text(_error!, style: const TextStyle(color: Colors.red)) : const Text('Locked'),
        ),
      );
    }
    // Filter entries by search
    final filteredEntries = _searchQuery.isEmpty
        ? _entries
        : _entries.where((e) =>
            e.appName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            e.username.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Password Vault')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search passwords...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: filteredEntries.isEmpty
                ? const Center(child: Text('No passwords found.'))
                : ListView.builder(
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, idx) {
                      final entry = filteredEntries[idx];
                      bool isPasswordVisible = _visiblePasswordIndex == idx;
                      return ListTile(
                        leading: entry.icon.isNotEmpty && entry.icon.length == 1
                            ? Text(entry.icon, style: const TextStyle(fontSize: 24))
                            : const Icon(Icons.vpn_key),
                        title: Text(entry.appName),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _visiblePasswordIndex = isPasswordVisible ? -1 : idx;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: isPasswordVisible
                                  ? () => _copyToClipboard(entry.password)
                                  : null,
                              tooltip: 'Copy password',
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _visiblePasswordIndex = isPasswordVisible ? -1 : idx;
                          });
                        },
                        onLongPress: () => _showEntryOptions(entry, idx),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        isThreeLine: isPasswordVisible,
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.username),
                            if (isPasswordVisible)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: SelectableText(entry.password, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _unlocked
          ? FloatingActionButton(
              onPressed: _showAddPasswordDialog,
              child: const Icon(Icons.add),
              tooltip: 'Add Password',
            )
          : null,
    );
  }

  int _visiblePasswordIndex = -1;
}
