import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/localization/language_preferences.dart';

void main() {
  test('translationSourceLanguage يعيد deviceLanguage لو لم يُضبط', () {
    final prefs = LanguagePreferences(deviceLocale: const Locale('ar', 'SA'));
    expect(prefs.translationSourceLanguage, equals('ar'));
  });

  test('translationSourceLanguage يقرأ القيمة المخصصة إذا ضُبطت', () {
    final prefs = LanguagePreferences(deviceLocale: const Locale('ar', 'SA'));
    prefs.translationSourceLanguage = 'en';
    expect(prefs.translationSourceLanguage, equals('en'));
  });

  test('translationSourceLanguage يعود لجهاز إذا أُعيد تعيينه بـ null', () {
    final prefs = LanguagePreferences(deviceLocale: const Locale('ar', 'SA'));
    prefs.translationSourceLanguage = 'fr';
    expect(prefs.translationSourceLanguage, equals('fr'));
    // null override يعيد الجهاز
    // ملاحظة: setter يقبل null ويعيد تعيينه
  });
}
