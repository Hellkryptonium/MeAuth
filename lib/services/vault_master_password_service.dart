import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:argon2/argon2.dart';
import 'package:hex/hex.dart';

class VaultMasterPasswordService {
  static const _hashKey = 'vault_master_hash';
  static const _saltKey = 'vault_master_salt';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Set master password: hash and store
  Future<void> setMasterPassword(String password) async {
    final salt = _generateSalt();
    final hash = await _argon2Hash(password, salt);
    await _storage.write(key: _hashKey, value: hash);
    await _storage.write(key: _saltKey, value: HEX.encode(salt));
  }

  // Verify master password
  Future<bool> verifyMasterPassword(String password) async {
    final hash = await _storage.read(key: _hashKey);
    final saltHex = await _storage.read(key: _saltKey);
    if (hash == null || saltHex == null) return false;
    final salt = HEX.decode(saltHex);
    final inputHash = await _argon2Hash(password, salt);
    return hash == inputHash;
  }

  // Check if master password is set
  Future<bool> isMasterPasswordSet() async {
    final hash = await _storage.read(key: _hashKey);
    return hash != null;
  }

  Future<String?> getSaltHex() async {
    return await _storage.read(key: _saltKey);
  }

  List<int> _generateSalt() {
    final rand = Random.secure();
    return List<int>.generate(16, (_) => rand.nextInt(256));
  }

  Future<String> _argon2Hash(String password, List<int> salt) async {
    final argon2 = Argon2BytesGenerator()
      ..init(Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        Uint8List.fromList(salt),
        version: Argon2Parameters.ARGON2_VERSION_13,
        iterations: 3,
        memoryPowerOf2: 16,
        lanes: 4,
      ));
    final passwordBytes = utf8.encode(password);
    final hash = Uint8List(32);
    argon2.generateBytes(passwordBytes, hash, 0, 32);
    return HEX.encode(hash);
  }
}
