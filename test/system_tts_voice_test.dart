import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/speech/system_tts_service.dart';

void main() {
  test('parses a valid platform voice map', () {
    final voice = SystemTtsVoice.fromPlatformMap(<String, dynamic>{
      'name': 'Arabic local voice',
      'locale': 'ar-SA',
    });

    expect(voice.name, 'Arabic local voice');
    expect(voice.supportsLocale('ar-EG'), isTrue);
    expect(voice.supportsLocale('en-US'), isFalse);
    expect(
      voice.toPlatformMap(),
      <String, String>{'name': 'Arabic local voice', 'locale': 'ar-SA'},
    );
  });

  test('rejects incomplete platform voice maps', () {
    expect(
      () => SystemTtsVoice.fromPlatformMap(<String, dynamic>{'name': 'voice'}),
      throwsFormatException,
    );
  });
}
