import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/localization/language_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('uses device language first then persists source and target preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = LanguagePreferences(deviceLocale: const Locale('en', 'US'));

    await preferences.initialize();

    expect(preferences.translationSourceLanguage, 'en');
    expect(preferences.translationTargetLanguage, 'ar');

    await preferences.setTranslationSourceLanguage('fr');
    await preferences.setTranslationTargetLanguage('de');

    SharedPreferences.setMockInitialValues(<String, Object>{
      'mirror_scorpion_translation_source': 'fr',
      'mirror_scorpion_translation_target': 'de',
    });
    final restored = LanguagePreferences(deviceLocale: const Locale('ar', 'SA'));
    await restored.initialize();

    expect(restored.translationSourceLanguage, 'fr');
    expect(restored.translationTargetLanguage, 'de');
  });
}
