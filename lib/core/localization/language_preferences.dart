import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يحتفظ بلغة هدف الترجمة فقط. لغة مصدر المايك هي أي لغة يختارها المستخدم في المربع الأيمن،
/// لذلك لا تحفظ كاختيار منفصل ولا تختلط بلغة واجهة التطبيق.
class LanguagePreferences extends ChangeNotifier {
  static const _legacySourceKey = 'mirror_scorpion_translation_source';
  static const _targetKey = 'mirror_scorpion_translation_target';

  LanguagePreferences({Locale? deviceLocale})
      : _deviceLocale = deviceLocale ?? PlatformDispatcher.instance.locale;

  final Locale _deviceLocale;
  late SharedPreferences _preferences;
  late String _targetLanguage = 'en';
  String? _sourceLanguageOverride;

  Locale get deviceLocale => _deviceLocale;
  String get deviceLanguageCode => _deviceLocale.languageCode.toLowerCase();
  String get translationTargetLanguage => _targetLanguage;

  /// لغة مايك الحوار المحفوظة. null = لم يختر المستخدم شيئاً بعد
  /// (وفي هذه الحالة تستخدم الواجهة لغة الجهاز كافتراض أول مرة فقط).
  String? get dialogueMicLanguageCode => _dialogueMicLanguage;

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
}
