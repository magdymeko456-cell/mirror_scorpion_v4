import 'dart:io';
import 'package:flutter/foundation.dart';

class AudioSharingCleanupService extends ChangeNotifier {
  static const String appSignature = 'MIRROR_SCORPION_OFFICIAL_AUDIO';
  String? _lastGeneratedAudioPath;

  String? get lastGeneratedAudioPath => _lastGeneratedAudioPath;

  void registerAudioFile(String path) {
    _lastGeneratedAudioPath = path;
    notifyListeners();
  }

  Future<void> deleteLastAudio() async {
    if (_lastGeneratedAudioPath != null) {
      try {
        final file = File(_lastGeneratedAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      _lastGeneratedAudioPath = null;
      notifyListeners();
    }
  }

  Future<void> onNewLineTranslated() async {
    await deleteLastAudio();
  }

  bool verifySignature(String path) {
    return path.contains('mirror_signed') || path.endsWith('.wav') || path.endsWith('.mp3');
  }
}
