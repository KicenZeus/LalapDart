import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppConfig {
  static const String appName = 'Lalapan';
  static const String appVersion = '1.0.0';

  /// IP Wi-Fi komputer backend agar bisa dijangkau oleh HP di jaringan yang sama
  static const String localNetworkHost = '192.168.23.33';
  static const int backendPort = 5055;

  /// Base URL backend REST API otomatis menyesuaikan target platform
  static String get apiBaseUrl {
    if (kIsWeb) {
      // Browser di laptop bisa langsung pakai localhost atau IP LAN
      return 'http://127.0.0.1:$backendPort/api';
    }

    try {
      if (Platform.isAndroid) {
        // Untuk perangkat fisik HP Android di jaringan Wi-Fi lokal yang sama
        return 'http://$localNetworkHost:$backendPort/api';
      } else if (Platform.isIOS) {
        // Untuk perangkat fisik iPhone di jaringan Wi-Fi lokal yang sama
        return 'http://$localNetworkHost:$backendPort/api';
      }
    } catch (_) {
      // Fallback
    }

    return 'http://$localNetworkHost:$backendPort/api';
  }

  /// Timeout jaringan
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
