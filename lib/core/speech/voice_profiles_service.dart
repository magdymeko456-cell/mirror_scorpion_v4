import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VoiceProfile {
  saif('سيف', VoiceGender.male, 'ar-SA'),
  salma('سلمى', VoiceGender.female, 'ar-SA'),
  sama('سما', VoiceGender.female, 'ar-SA'),
  sara('سارة', VoiceGender.female, 'ar-SA'),
  user('صوت تامر', VoiceGender.other, 'ar-SA');

  const VoiceProfile(this.label, this.gender, this.defaultLocale);
  final String label;
  final VoiceGender gender;
  final String defaultLocale;
}

enum VoiceGender { male, female, other }

class VoiceProfilesService extends ChangeNotifier {
  VoiceProfile _selectedProfile = VoiceProfile.saif;
  String? _userVoiceSamplePath;
  bool _userVoiceTrained = false;

  VoiceProfile get selectedProfile => _selectedProfile;
  String? get userVoiceSamplePath => _userVoiceSamplePath;
  bool get userVoiceTrained => _userVoiceTrained;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('mirror_scorpion_voice_profile');
    if (saved != null) {
      _selectedProfile = VoiceProfile.values.firstWhere(
        (p) => p.name == saved,
        orElse: () => VoiceProfile.saif,
      );
    }
    notifyListeners();
  }

  Future<void> selectProfile(VoiceProfile profile) async {
    _selectedProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mirror_scorpion_voice_profile', profile.name);
    notifyListeners();
  }

  Future<void> trainUserVoice(String samplePath) async {
    _userVoiceSamplePath = samplePath;
    _userVoiceTrained = true;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    final tts = FlutterTts();
    await tts.setLanguage(_selectedProfile.defaultLocale);

    switch (_selectedProfile) {
      case VoiceProfile.saif:
        await tts.setPitch(0.85);
        await tts.setSpeechRate(0.45);
        break;
      case VoiceProfile.salma:
        await tts.setPitch(1.15);
        await tts.setSpeechRate(0.50);
        break;
      case VoiceProfile.sama:
        await tts.setPitch(1.35);
        await tts.setSpeechRate(0.42);
        break;
      case VoiceProfile.sara:
        await tts.setPitch(1.05);
        await tts.setSpeechRate(0.55);
        break;
      case VoiceProfile.user:
        await tts.setPitch(1.0);
        await tts.setSpeechRate(0.50);
        break;
    }

    await tts.speak(text);
  }
}
