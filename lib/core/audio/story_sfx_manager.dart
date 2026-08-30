
import 'package:audioplayers/audioplayers';
import 'package:flutter/foundation.dart';

class StorySfxManager {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _isMuted = false;

  Future<void> playEffect(String sfxName) async {
    if (_isMuted) return;
    try {
      // تشغيل المؤثر الصوتي من مجلد الأصول assets/audio/sfx/
      await _sfxPlayer.play(AssetSource('audio/sfx/$sfxName.mp3'));
      await _sfxPlayer.setVolume(0.4); // مستوى خلفي هادئ لا يطغى على السرد
    } catch (e) {
      debugPrint('⚠️ تعذر تشغيل المؤثر الصوتي $sfxName: $e');
    }
  }

  Future<void> stopEffect() async {
    await _sfxPlayer.stop();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) stopEffect();
  }

  bool get isMuted => _isMuted;
}
