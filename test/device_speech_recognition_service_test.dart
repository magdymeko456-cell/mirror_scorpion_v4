import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/speech/device_speech_recognition_service.dart';

void main() {
  group('SpeechLocaleResolver', () {
    test('matches a source language to an installed recognition locale', () {
      expect(
        SpeechLocaleResolver.preferredLocaleId(
          languageCode: 'ar',
          installedLocaleIds: const ['en_US', 'ar-EG'],
        ),
        'ar-EG',
      );
    });

    test('matches English speech to an installed regional locale', () {
      expect(
        SpeechLocaleResolver.preferredLocaleId(
          languageCode: 'en',
          installedLocaleIds: const ['ar_EG', 'en-US'],
        ),
        'en-US',
      );
    });

    test('allows the device default when a matching locale is absent', () {
      expect(
        SpeechLocaleResolver.preferredLocaleId(
          languageCode: 'ar',
          installedLocaleIds: const ['en_US', 'fr-FR'],
        ),
        isNull,
      );
    });
  });
}
