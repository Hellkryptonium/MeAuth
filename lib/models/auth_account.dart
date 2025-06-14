import 'package:flutter/foundation.dart';

enum OtpType { totp, hotp }

class AuthAccount {
  final String label;
  final String secret;
  final OtpType type;
  final String? issuer;
  final int digits;
  final int period; // For TOTP
  final int? counter; // For HOTP
  final String algorithm; // Add algorithm
  final String icon; // New: icon name or emoji

  AuthAccount({
    required this.label,
    required this.secret,
    this.type = OtpType.totp,
    this.issuer,
    this.digits = 6,
    this.period = 30,
    this.counter,
    this.algorithm = 'SHA1',
    this.icon = 'key', // Default icon
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'secret': secret,
        'type': describeEnum(type),
        'issuer': issuer,
        'digits': digits,
        'period': period,
        'counter': counter,
        'algorithm': algorithm,
        'icon': icon,
      };

  factory AuthAccount.fromJson(Map<String, dynamic> json) => AuthAccount(
        label: json['label'],
        secret: json['secret'],
        type: json['type'] == 'hotp' ? OtpType.hotp : OtpType.totp,
        issuer: json['issuer'],
        digits: json['digits'] ?? 6,
        period: json['period'] ?? 30,
        counter: json['counter'],
        algorithm: json['algorithm'] ?? 'SHA1',
        icon: json['icon'] ?? 'key',
      );
}
