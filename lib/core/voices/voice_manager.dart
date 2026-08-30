
import 'package:flutter/foundation.dart';

enum VoicePersona { saif, salma, sama, sara, userVoice }

class VoiceProfileConfig {
  final VoicePersona persona;
  final String nameAr;
  final double pitch;
  final double speechRate;
  final bool isPaidOnly;

  const VoiceProfileConfig({
    required this.persona,
    required this.nameAr,
    required this.pitch,
    required this.speechRate,
    this.isPaidOnly = false,
  });
}

class VoiceManager extends ChangeNotifier {
  VoicePersona _currentPersona = VoicePersona.saif;
  bool _isPaidVersionUnlocked = false; // يمكن ربطها بترخيص التطبيق

  static const Map<VoicePersona, VoiceProfileConfig> profiles = {
    VoicePersona.saif: VoiceProfileConfig(
      persona: VoicePersona.saif,
      nameAr: 'سيف (صوت ذكوري عميق)',
      pitch: 0.85,
      speechRate: 0.95,
    ),
    VoicePersona.salma: VoiceProfileConfig(
      persona: VoicePersona.salma,
      nameAr: 'سلمى (صوت نسائي دافئ)',
      pitch: 1.2,
      speechRate: 1.0,
    ),
    VoicePersona.sama: VoiceProfileConfig(
      persona: VoicePersona.sama,
      nameAr: 'سما (صوت نسائي حيوي)',
      pitch: 1.3,
      speechRate: 1.05,
    ),
    VoicePersona.sara: VoiceProfileConfig(
      persona: VoicePersona.sara,
      nameAr: 'سارة (صوت نسائي هادئ)',
      pitch: 1.15,
      speechRate: 0.9,
    ),
    VoicePersona.userVoice: VoiceProfileConfig(
      persona: VoicePersona.userVoice,
      nameAr: 'صوتك الخاص (استنساخ محلي)',
      pitch: 1.0,
      speechRate: 1.0,
      isPaidOnly: true,
    ),
  };

  VoicePersona get currentPersona => _currentPersona;
  VoiceProfileConfig get currentConfig => profiles[_currentPersona]!;
  bool get isPaidUnlocked => _isPaidVersionUnlocked;

  void setPersona(VoicePersona persona) {
    if (profiles[persona]?.isPaidOnly == true && !_isPaidVersionUnlocked) {
      debugPrint('⚠️ صوت المستخدم متاح حصرياً في النسخة المدفوعة.');
      return;
    }
    _currentPersona = persona;
    notifyListeners();
  }

  void setPaidUnlocked(bool unlocked) {
    _isPaidVersionUnlocked = unlocked;
    notifyListeners();
  }
}
