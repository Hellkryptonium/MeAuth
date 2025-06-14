import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

class VaultCryptoService {
  // Encrypts plaintext with AES-GCM using the provided key
  static String encryptVault(String plaintext, List<int> key) {
    final aesKey = encrypt.Key(Uint8List.fromList(key));
    final iv = encrypt.IV.fromSecureRandom(12); // 12 bytes for GCM
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    // Store IV and ciphertext together (base64)
    final result = json.encode({
      'iv': iv.base64,
      'ciphertext': encrypted.base64,
    });
    return result;
  }

  // Decrypts vault data with AES-GCM using the provided key
  static String decryptVault(String encryptedJson, List<int> key) {
    final map = json.decode(encryptedJson);
    final aesKey = encrypt.Key(Uint8List.fromList(key));
    final iv = encrypt.IV.fromBase64(map['iv']);
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.gcm));
    final encrypted = encrypt.Encrypted.fromBase64(map['ciphertext']);
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
