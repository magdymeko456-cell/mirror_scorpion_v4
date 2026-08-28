import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppVoice { saif, salma, sama, sara, ownerCloned }

class VoiceSelectionService extends ChangeNotifier {
  static const String _voiceKey = 'mirror_selected_voice';
  static const String _clonedVoicePathKey = 'mirror_cloned_voice_path';

  AppVoice _selectedVoice = AppVoice.saif;
  String? _clonedVoicePath;

  AppVoice get selectedVoice => _selectedVoice;
  String? get clonedVoicePath => _clonedVoicePath;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVoice = prefs.getString(_voiceKey);
    _clonedVoicePath = prefs.getString(_clonedVoicePathKey);

    if (savedVoice != null) {
      _selectedVoice = AppVoice.values.firstWhere(
        (v) => v.name == savedVoice,
        orElse: () => AppVoice.saif,
      );
    }
    notifyListeners();
  }

  Future<void> selectVoice(AppVoice voice) async {
    _selectedVoice = voice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voiceKey, voice.name);
    notifyListeners();
  }

  Future<void> registerOwnerClonedVoice(String filePath) async {
    _clonedVoicePath = filePath;
    _selectedVoice = AppVoice.ownerCloned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clonedVoicePathKey, filePath);
    await prefs.setString(_voiceKey, AppVoice.ownerCloned.name);
    notifyListeners();
  }
}
