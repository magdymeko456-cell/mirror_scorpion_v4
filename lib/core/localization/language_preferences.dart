import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يحتفظ باللغة التي اختارها المستخدم في تدفقات الترجمة، ويستخدم لغة الجهاز
/// كبداية فقط عندما لا توجد تفضيلات محفوظة. لا يترجم نصوص الواجهة ذاتها.
class LanguagePreferences extends ChangeNotifier {
  static const _sourceKey = 'mirror_scorpion_translation_source';
  static const _targetKey = 'mirror_scorpion_translation_target';

  LanguagePreferences({Locale? deviceLocale})
      : _deviceLocale = deviceLocale ?? PlatformDispatcher.instance.locale;

  final Locale _deviceLocale;
  late SharedPreferences _preferences;
  late String _sourceLanguage = deviceLanguageCode;
  late String _targetLanguage =
      deviceLanguageCode == 'ar' ? 'en' : 'ar';

  Locale get deviceLocale => _deviceLocale;
  String get deviceLanguageCode => _deviceLocale.languageCode.toLowerCase();
  String get translationSourceLanguage => _sourceLanguage;
  String get translationTargetLanguage => _targetLanguage;
  String get storyLanguageCode => deviceLanguageCode;

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    final fallbackSource = deviceLanguageCode;
    _sourceLanguage = _preferences.getString(_sourceKey) ?? fallbackSource;
    _targetLanguage = _preferences.getString(_targetKey) ??
        (fallbackSource == 'ar' ? 'en' : 'ar');
  }

  Future<void> setTranslationSourceLanguage(String code) async {
    _sourceLanguage = code.toLowerCase();
    await _preferences.setString(_sourceKey, _sourceLanguage);
    notifyListeners();
  }

  Future<void> setTranslationTargetLanguage(String code) async {
    _targetLanguage = code.toLowerCase();
    await _preferences.setString(_targetKey, _targetLanguage);
    notifyListeners();
  }

  Future<void> swapTranslationLanguages() async {
    final oldSource = _sourceLanguage;
    _sourceLanguage = _targetLanguage;
    _targetLanguage = oldSource;
    await _preferences.setString(_sourceKey, _sourceLanguage);
    await _preferences.setString(_targetKey, _targetLanguage);
    notifyListeners();
  }
}
