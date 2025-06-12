import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_account.dart';

class AccountStorageService {
  static const _storageKey = 'accounts';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<AuthAccount>> loadAccounts() async {
    final jsonStr = await _storage.read(key: _storageKey);
    if (jsonStr == null) return [];
    final List<dynamic> data = json.decode(jsonStr);
    return data.map((e) => AuthAccount.fromJson(e)).toList();
  }

  Future<void> saveAccounts(List<AuthAccount> accounts) async {
    final jsonStr = json.encode(accounts.map((e) => e.toJson()).toList());
    await _storage.write(key: _storageKey, value: jsonStr);
  }

  Future<void> clear() async {
    await _storage.delete(key: _storageKey);
  }
}
