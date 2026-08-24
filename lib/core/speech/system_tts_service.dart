import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum SystemSpeechState { idle, speaking, unavailable, failed }

class SystemTtsVoice {
  const SystemTtsVoice({required this.name, required this.locale});

  final String name;
  final String locale;

  factory SystemTtsVoice.fromPlatformMap(Map<dynamic, dynamic> value) {
    final name = value['name'];
    final locale = value['locale'];
    if (name is! String || name.trim().isEmpty ||
        locale is! String || locale.trim().isEmpty) {
      throw const FormatException('Invalid system TTS voice.');
    }
    return SystemTtsVoice(name: name, locale: locale);
  }

  bool supportsLocale(String requestedLocale) =>
      _languagePart(locale) == _languagePart(requestedLocale);

  Map<String, String> toPlatformMap() => <String, String>{
        'name': name,
        'locale': locale,
      };

  @override
  bool operator ==(Object other) =>
      other is SystemTtsVoice && other.name == name && other.locale == locale;

  @override
  int get hashCode => Object.hash(name, locale);

  static String _languagePart(String locale) =>
      locale.replaceAll('_', '-').split('-').first.toLowerCase();
}

class SystemTtsService extends ChangeNotifier {
  SystemTtsService() : _tts = FlutterTts();

  final FlutterTts _tts;
  SystemSpeechState _state = SystemSpeechState.idle;
  String? _message;
  SystemTtsVoice? _selectedVoice;

  SystemSpeechState get state => _state;
  String? get message => _message;
  bool get isSpeaking => _state == SystemSpeechState.speaking;
  SystemTtsVoice? get selectedVoice => _selectedVoice;

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
      final voice = _selectedVoice;
      if (voice != null && voice.supportsLocale(locale)) {
        await _tts.setVoice(voice.toPlatformMap());
      } else if (voice != null) {
        await _tts.clearVoice();
      }
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

  Future<List<SystemTtsVoice>> voicesForLanguage(String languageCode) async {
    final requestedLocale = _localeFor(languageCode);
    try {
      final rawVoices = await _tts.getVoices;
      if (rawVoices is! List) return const <SystemTtsVoice>[];
      final voices = <SystemTtsVoice>[];
      for (final rawVoice in rawVoices) {
        if (rawVoice is! Map) continue;
        try {
          final voice = SystemTtsVoice.fromPlatformMap(rawVoice);
          if (voice.supportsLocale(requestedLocale)) voices.add(voice);
        } on FormatException {
          // محرك النظام قد يعيد سجلاً ناقصاً؛ لا نعرضه للمستخدم.
        }
      }
      voices.sort((left, right) => left.name.compareTo(right.name));
      return voices;
    } catch (_) {
      _message = 'تعذر قراءة قائمة أصوات النظام في هذا الجهاز.';
      notifyListeners();
      return const <SystemTtsVoice>[];
    }
  }

  Future<bool> selectVoice(
    SystemTtsVoice? voice, {
    required String languageCode,
  }) async {
    final requestedLocale = _localeFor(languageCode);
    if (voice != null && !voice.supportsLocale(requestedLocale)) {
      _state = SystemSpeechState.unavailable;
      _message = 'هذا الصوت لا يدعم لغة القصة الحالية.';
      notifyListeners();
      return false;
    }
    try {
      if (voice == null) {
        await _tts.clearVoice();
      } else {
        await _tts.setVoice(voice.toPlatformMap());
      }
      _selectedVoice = voice;
      _state = SystemSpeechState.idle;
      _message = voice == null
          ? 'سيستخدم التطبيق صوت النظام الافتراضي.'
          : 'تم اختيار صوت النظام: ${voice.name}.';
      notifyListeners();
      return true;
    } catch (_) {
      _state = SystemSpeechState.failed;
      _message = 'تعذر اختيار صوت النظام المطلوب.';
      notifyListeners();
      return false;
    }
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
