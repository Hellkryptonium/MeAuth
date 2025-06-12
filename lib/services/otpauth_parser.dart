import 'dart:core';
import 'package:flutter/foundation.dart';
import '../models/auth_account.dart';

class OtpAuthParser {
  static AuthAccount? parse(String uri) {
    try {
      debugPrint('Scanned otpauth URI: ' + uri);
      final uriObj = Uri.parse(uri);
      if (uriObj.scheme != 'otpauth') return null;
      final type = uriObj.host == 'hotp' ? OtpType.hotp : OtpType.totp;
      final label = uriObj.pathSegments.isNotEmpty ? Uri.decodeComponent(uriObj.pathSegments.join('/')) : '';
      final query = uriObj.queryParameters;
      final secret = query['secret'] ?? '';
      final issuer = query['issuer'];
      final digits = int.tryParse(query['digits'] ?? '') ?? 6;
      final period = int.tryParse(query['period'] ?? '') ?? 30;
      final counter = type == OtpType.hotp ? int.tryParse(query['counter'] ?? '') ?? 0 : null;
      final algorithm = (query['algorithm'] ?? 'SHA1').toUpperCase();
      if (secret.isEmpty || label.isEmpty) return null;
      return AuthAccount(
        label: label,
        secret: secret,
        type: type,
        issuer: issuer,
        digits: digits,
        period: period,
        counter: counter,
        algorithm: algorithm,
      );
    } catch (_) {
      return null;
    }
  }
}
