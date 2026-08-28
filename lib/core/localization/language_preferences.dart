import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguagePreferences extends ChangeNotifier {
  static const String _sourceLangKey = 'mirror_scorpion_source_lang';
  static const String _targetLangKey = 'mirror_scorpion_target_lang';
  static const String _autoDetectKey = 'mirror_scorpion_auto_detect';

  String _sourceLanguage = 'ar';
  String _targetLanguage = 'en';
  bool _autoDetect = false;

  String get sourceLanguage => _sourceLanguage;
  String get targetLanguage => _targetLanguage;
  bool get autoDetect => _autoDetect;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _sourceLanguage = prefs.getString(_sourceLangKey) ?? 'ar';
    _targetLanguage = prefs.getString(_targetLangKey) ?? 'en';
    _autoDetect = prefs.getBool(_autoDetectKey) ?? false;
    notifyListeners();
  }

  Future<void> setSourceLanguage(String code) async {
    if (_sourceLanguage == code) return;
    _sourceLanguage = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sourceLangKey, code);
    notifyListeners();
  }

  Future<void> setTargetLanguage(String code) async {
    if (_targetLanguage == code) return;
    _targetLanguage = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_targetLangKey, code);
    notifyListeners();
  }

  Future<void> swapLanguages() async {
    final temp = _sourceLanguage;
    _sourceLanguage = _targetLanguage;
    _targetLanguage = temp;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sourceLangKey, _sourceLanguage);
    await prefs.setString(_targetLangKey, _targetLanguage);
    notifyListeners();
  }

  Future<void> setAutoDetect(bool enabled) async {
    _autoDetect = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoDetectKey, enabled);
    notifyListeners();
  }
}
