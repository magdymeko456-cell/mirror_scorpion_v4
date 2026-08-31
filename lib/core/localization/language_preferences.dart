import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يحتفظ بلغة هدف الترجمة فقط. لغة مصدر الميكروفون هي لغة الجهاز دائماً،
/// لذلك لا تحفظ كاختيار منفصل ولا تختلط بلغة واجهة التطبيق.
class LanguagePreferences extends ChangeNotifier {
  static const _legacySourceKey = 'mirror_scorpion_translation_source';
  static const _targetKey = 'mirror_scorpion_translation_target';

  LanguagePreferences({Locale? deviceLocale})
      : _deviceLocale = deviceLocale ?? PlatformDispatcher.instance.locale;

  final Locale _deviceLocale;
  late SharedPreferences _preferences;
  late String _targetLanguage = 'en';

  Locale get deviceLocale => _deviceLocale;
  String get deviceLanguageCode => _deviceLocale.languageCode.toLowerCase();
  String get translationSourceLanguage => deviceLanguageCode;
  String get translationTargetLanguage => _targetLanguage;
  String get storyLanguageCode => deviceLanguageCode;

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    await _preferences.remove(_legacySourceKey);
    _targetLanguage = _preferences.getString(_targetKey) ?? 'en';
  }

  @Deprecated('لغة مصدر المايك هي لغة الجهاز دائماً.')
  Future<void> setTranslationSourceLanguage(String code) async {
    await _preferences.remove(_legacySourceKey);
    notifyListeners();
  }

  Future<void> setTranslationTargetLanguage(String code) async {
    _targetLanguage = code.toLowerCase();
    await _preferences.setString(_targetKey, _targetLanguage);
    notifyListeners();
  }

  @Deprecated('لا يمكن تبديل لغة جهاز المايك مع لغة الترجمة.')
  Future<void> swapTranslationLanguages() async {
    await _preferences.remove(_legacySourceKey);
    notifyListeners();
  }

  // [تم الحقن بواسطة سكربت الأدوات - حفظ واسترجاع آخر لغة]
  static const String _lastLangKey = 'last_used_translation_language';

  Future<void> saveLastLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLangKey, langCode);
  }

  Future<String?> getLastLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastLangKey);
  }

}
