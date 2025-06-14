import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:argon2/argon2.dart';
import 'package:hex/hex.dart';

class KeyDerivationService {
  static const int saltLength = 16;
  static const int keyLength = 32; // 256-bit key

  /// Generates a random salt
  static List<int> generateSalt() {
    final rand = Random.secure();
    return List<int>.generate(saltLength, (_) => rand.nextInt(256));
  }

  /// Derives a key from the password and salt using Argon2id
  static Future<List<int>> deriveKey(String password, List<int> salt) async {
    final argon2 = Argon2BytesGenerator()
      ..init(Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        Uint8List.fromList(salt),
        version: Argon2Parameters.ARGON2_VERSION_13,
        iterations: 3, // Increase for more security
        memoryPowerOf2: 16, // 64 MiB
        lanes: 4,
      ));
    final passwordBytes = utf8.encode(password);
    final key = Uint8List(keyLength);
    argon2.generateBytes(passwordBytes, key, 0, keyLength);
    return key;
  }

  /// Synchronous version for use with compute
  static List<int> deriveKeySync(String password, List<int> salt) {
    final argon2 = Argon2BytesGenerator()
      ..init(Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        Uint8List.fromList(salt),
        version: Argon2Parameters.ARGON2_VERSION_13,
        iterations: 3, // Increase for more security
        memoryPowerOf2: 16, // 64 MiB
        lanes: 4,
      ));
    final passwordBytes = utf8.encode(password);
    final key = Uint8List(keyLength);
    argon2.generateBytes(passwordBytes, key, 0, keyLength);
    return key;
  }

  /// Encodes salt as hex for storage
  static String saltToHex(List<int> salt) => HEX.encode(salt);

  /// Decodes salt from hex
  static List<int> saltFromHex(String hexSalt) => HEX.decode(hexSalt);
}
