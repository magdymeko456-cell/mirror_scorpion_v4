
import 'package:flutter/foundation.dart';
import '../audio/story_sfx_manager.dart';

class StoryAudioEngine {
  final StorySfxManager _sfxManager = StorySfxManager();

  // تشغيل مؤثر مناسب حسب نوع المشهد في القصة
  Future<void> playSceneEffect(String sceneTag) async {
    String sfxName = 'wind'; // افتراضي
    
    switch (sceneTag.toLowerCase()) {
      case 'sea':
      case 'ocean':
      case 'water':
        sfxName = 'sea';
        break;
      case 'desert':
      case 'sand':
      case 'wind':
        sfxName = 'sand';
        break;
      case 'battle':
      case 'horses':
      case 'run':
        sfxName = 'horses';
        break;
      default:
        sfxName = 'wind';
    }

    await _sfxManager.playEffect(sfxName);
    debugPrint('🎶 تم تشغيل مؤثر المشهد: $sfxName');
  }

  Future<void> stopAllEffects() async {
    await _sfxManager.stopEffect();
  }
}
