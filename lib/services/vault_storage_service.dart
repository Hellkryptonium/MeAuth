import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/vault_entry.dart';

class VaultStorageService {
  static const _storageKey = 'vault_data';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveEncryptedVault(String encryptedJson) async {
    await _storage.write(key: _storageKey, value: encryptedJson);
  }

  Future<String?> loadEncryptedVault() async {
    return await _storage.read(key: _storageKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _storageKey);
  }
}
