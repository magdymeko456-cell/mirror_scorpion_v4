import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum SystemSpeechState { idle, speaking, unavailable, failed }

class SystemTtsService extends ChangeNotifier {
  SystemTtsService() : _tts = FlutterTts();

  final FlutterTts _tts;
  SystemSpeechState _state = SystemSpeechState.idle;
  String? _message;

  SystemSpeechState get state => _state;
  String? get message => _message;
  bool get isSpeaking => _state == SystemSpeechState.speaking;

  Future<void> initialize() async {
    _tts.setStartHandler(() {
      _state = SystemSpeechState.speaking;
      _message = 'جارٍ النطق بصوت النظام…';
      notifyListeners();
    });
    _tts.setCompletionHandler(_markIdle);
    _tts.setCancelHandler(_markIdle);
    _tts.setErrorHandler((_) {
      _state = SystemSpeechState.failed;
      _message = 'تعذر تشغيل صوت النظام للنص المحدد.';
      notifyListeners();
    });
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  Future<bool> speak({required String text, required String languageCode}) async {
    final content = text.trim();
    if (content.isEmpty) {
      _state = SystemSpeechState.unavailable;
      _message = 'لا يوجد نص لقراءته.';
      notifyListeners();
      return false;
    }
    final locale = _localeFor(languageCode);
    try {
      final available = await _tts.isLanguageAvailable(locale);
      if (available != true) {
        _state = SystemSpeechState.unavailable;
        _message = 'صوت النظام للغة $locale غير متاح على هذا الجهاز.';
        notifyListeners();
        return false;
      }
      await _tts.stop();
      await _tts.setLanguage(locale);
      final result = await _tts.speak(content, focus: true);
      if (result == 1) return true;
      _state = SystemSpeechState.failed;
      _message = 'لم يبدأ صوت النظام. جرّب تنزيل صوت لهذه اللغة من إعدادات الجهاز.';
      notifyListeners();
      return false;
    } catch (_) {
      _state = SystemSpeechState.failed;
      _message = 'تعذر تهيئة صوت النظام للغة المطلوبة.';
      notifyListeners();
      return false;
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    _markIdle();
  }

  void _markIdle() {
    _state = SystemSpeechState.idle;
    _message = null;
    notifyListeners();
  }

  String _localeFor(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ar':
        return 'ar-SA';
      case 'en':
        return 'en-US';
      case 'fr':
        return 'fr-FR';
      case 'es':
        return 'es-ES';
      case 'de':
        return 'de-DE';
      case 'pt':
        return 'pt-PT';
      case 'zh':
        return 'zh-CN';
      case 'ja':
        return 'ja-JP';
      case 'ko':
        return 'ko-KR';
      case 'ru':
        return 'ru-RU';
      case 'tr':
        return 'tr-TR';
      default:
        return languageCode;
    }
  }
}
