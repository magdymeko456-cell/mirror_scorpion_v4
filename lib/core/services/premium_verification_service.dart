import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumVerificationService extends ChangeNotifier {
  static const String _premiumKey = 'mirror_scorpion_is_premium';

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumKey) ?? false;
    notifyListeners();
  }

  Future<void> setPremiumStatus(bool status) async {
    _isPremium = status;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, status);
    notifyListeners();
  }

  Future<bool> verifyLicenseKey(String key) async {
    if (key.trim() == 'MIRROR_PRO_2026') {
      await setPremiumStatus(true);
      return true;
    }
    return false;
  }
}
