import 'package:flutter/foundation.dart';

class VaultEntry {
  final String id;
  final String appName;
  final String username;
  final String password; // Encrypted
  final String icon; // Emoji or Material icon name

  VaultEntry({
    required this.id,
    required this.appName,
    required this.username,
    required this.password,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'appName': appName,
        'username': username,
        'password': password,
        'icon': icon,
      };

  factory VaultEntry.fromJson(Map<String, dynamic> json) => VaultEntry(
        id: json['id'],
        appName: json['appName'],
        username: json['username'],
        password: json['password'],
        icon: json['icon'],
      );
}
