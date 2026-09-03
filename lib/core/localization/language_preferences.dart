import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يحتفظ بلغة هدف الترجمة ولغة مصدر المرئي كمصدر قابل للتحديد من الواجهة.
/// لغة المربع الأيمن (سياق المرئي) هي التي تمرر للمحرر، ولا ترتبط بلغة الجهاز.
class LanguagePreferences extends ChangeNotifier {
  static const _legacySourceKey = 'mirror_scorpion_translation_source';
  static const _targetKey = 'mirror_scorpion_translation_target';

  LanguagePreferences({Locale? deviceLocale})
      : _deviceLocale = deviceLocale ?? PlatformDispatcher.instance.locale;

  final Locale _deviceLocale;
  late SharedPreferences _preferences;
  late String _targetLanguage = 'en';

  /// لغة المصدر التي تعرضها المربع الأيمن؛ تبدأ من لغة الجهاز وتتغير
  /// إلى أي خيار من المستخدم بلا قيود لغة أو مقاس.
  String _sourceLanguage = 'en';

  Locale get deviceLocale => _deviceLocale;
  String get deviceLanguageCode => _deviceLocale.languageCode.toLowerCase();

  String get translationSourceLanguage => _sourceLanguage;
  set translationSourceLanguage(String code) {
    final normalized = code.toLowerCase();
    _sourceLanguage = normalized;
    notifyListeners();
  }

  String get translationTargetLanguage => _targetLanguage;
  set translationTargetLanguage(String code) {
    _targetLanguage = code.toLowerCase();
    notifyListeners();
  }

  String get storyLanguageCode => deviceLanguageCode;

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    await _preferences.remove(_legacySourceKey);
    // في أول إطلاق نبسط بلغة الجهاز لتظهر في المربع الأيمن الافتراضي
    _sourceLanguage = _preferences.getString('mirror_scorpion_source_language') ?? deviceLanguageCode;
    _targetLanguage = _preferences.getString(_targetKey) ?? 'en';
  }

  Future<void> setTranslationTargetLanguage(String code) async {
    translationTargetLanguage = code;
    await _preferences.setString(_targetKey, _targetLanguage);
  }

  Future<void> swapTranslationLanguages() async {
    final target = translationTargetLanguage;
    translationTargetLanguage = translationSourceLanguage;
    translationSourceLanguage = target;
    await _preferences.setString('mirror_scorpion_source_language', translationSourceLanguage);
  }
}
