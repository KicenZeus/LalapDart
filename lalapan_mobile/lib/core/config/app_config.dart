import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppConfig {
  static const String appName = 'Lalapan';
  static const String appVersion = '1.0.0';

  /// IP Wi-Fi komputer backend agar bisa dijangkau oleh HP di jaringan yang sama
  static const String localNetworkHost = '192.168.23.33';
  static const int backendPort = 5055;

  static String? customBaseUrl;

  /// Base URL backend REST API otomatis menyesuaikan target platform
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:$backendPort/api';
    }

    try {
      if (Platform.isAndroid) {
        // Default 127.0.0.1 (ADB Reverse via USB) untuk keandalan maksimal tanpa blokir firewall
        return 'http://127.0.0.1:$backendPort/api';
      } else if (Platform.isIOS) {
        return 'http://$localNetworkHost:$backendPort/api';
      }
    } catch (_) {}

    return 'http://127.0.0.1:$backendPort/api';
  }

  static String get apiBaseUrl => customBaseUrl ?? defaultBaseUrl;

  /// Timeout jaringan
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
