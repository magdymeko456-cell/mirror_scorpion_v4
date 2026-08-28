import 'dart:io';
import 'package:flutter/foundation.dart';

class DeviceIntegrityCheck {
  const DeviceIntegrityCheck._();

  static const List<String> _suPaths = [
    '/system/bin/su',
    '/system/xbin/su',
    '/sbin/su',
    '/system/sd/xbin/su',
    '/system/bin/failsafe/su',
    '/data/local/su',
    '/data/local/xbin/su',
    '/data/local/bin/su',
  ];

  static Future<bool> isDeviceCompromised() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _checkAndroidRoot();
    }
    return false;
  }

  static Future<bool> _checkAndroidRoot() async {
    try {
      for (final path in _suPaths) {
        if (await File(path).exists()) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static String getDeviceFingerprint() {
    return 'MS4_${DateTime.now().millisecondsSinceEpoch}';
  }
}
