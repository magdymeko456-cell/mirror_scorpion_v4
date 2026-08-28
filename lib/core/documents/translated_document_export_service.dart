import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslatedDocumentExportService extends ChangeNotifier {
  static const int freeWordLimit = 50;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('mirror_scorpion_is_premium') ?? false;
    notifyListeners();
  }

  int getWordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  bool canExportDocument(String text) {
    if (_isPremium) return true;
    return getWordCount(text) <= freeWordLimit;
  }

  String applyWatermark(String translatedText) {
    const watermark = "\n\n---\nتمت الترجمة بواسطة تطبيق ميرور سكوربيون (Mirror Scorpion)";
    return "$translatedText$watermark";
  }
}
