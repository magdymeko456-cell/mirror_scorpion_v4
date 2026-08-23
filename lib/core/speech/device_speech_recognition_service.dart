import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// غلاف محدود لتعرف الكلام الذي يوفره جهاز المستخدم. لا يسجل الصوت في
/// التطبيق ولا يرفع ملفات صوتية؛ طريقة المعالجة (محلية/عن بُعد) يحددها نظام
/// التعرف المثبت على الهاتف.
class DeviceSpeechRecognitionService extends ChangeNotifier {
  DeviceSpeechRecognitionService({stt.SpeechToText? speechToText})
      : _speechToText = speechToText ?? stt.SpeechToText();

  final stt.SpeechToText _speechToText;
  bool _isReady = false;
  String? _message;
  ValueChanged<String>? _onText;

  bool get isListening => _speechToText.isListening;
  bool get isReady => _isReady;
  String? get message => _message;

  Future<bool> start({
    required String languageCode,
    required ValueChanged<String> onText,
  }) async {
    _onText = onText;
    try {
      if (!_isReady) {
        _isReady = await _speechToText.initialize(
          onStatus: _handleStatus,
          onError: _handleError,
        );
      }
      if (!_isReady) {
        _message = 'تعرف الكلام غير متاح أو رُفض إذن الميكروفون على هذا الجهاز.';
        notifyListeners();
        return false;
      }

      final installedLocales = await _speechToText.locales();
      final localeId = SpeechLocaleResolver.preferredLocaleId(
        languageCode: languageCode,
        installedLocaleIds: installedLocales.map((locale) => locale.localeId),
      );
      await _speechToText.listen(
        onResult: _handleResult,
        listenOptions: stt.SpeechListenOptions(localeId: localeId),
      );
      _message = 'استمع الآن؛ سيظهر النص المعترف به في محرر المصدر.';
      notifyListeners();
      return true;
    } catch (_) {
      _message = 'تعذر بدء تعرف الكلام. تأكد من إذن الميكروفون وخدمة التعرف في الهاتف.';
      notifyListeners();
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _speechToText.stop();
    } catch (_) {
      _message = 'تعذر إيقاف تعرف الكلام بشكل سليم.';
      notifyListeners();
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.trim();
    if (text.isNotEmpty) _onText?.call(text);
  }

  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _message = 'انتهى الاستماع. راجع النص قبل ترجمته.';
    }
    notifyListeners();
  }

  void _handleError(SpeechRecognitionError error) {
    _message = error.permanent
        ? 'تعذر تعرف الكلام: ${error.errorMsg}. راجع إعدادات الجهاز.'
        : 'توقف تعرف الكلام مؤقتاً: ${error.errorMsg}.';
    notifyListeners();
  }

  @override
  void dispose() {
    _speechToText.cancel();
    super.dispose();
  }
}

/// يطابق لغة المصدر مع لغة تعرف مثبّتة على الهاتف، ثم يعيد null ليستعمل
/// النظام لغته الافتراضية عندما لا تتوفر مطابقة صريحة.
class SpeechLocaleResolver {
  const SpeechLocaleResolver._();

  static String? preferredLocaleId({
    required String languageCode,
    required Iterable<String> installedLocaleIds,
  }) {
    final normalized = languageCode.toLowerCase();
    for (final localeId in installedLocaleIds) {
      final localeLanguage = localeId
          .replaceAll('_', '-')
          .split('-')
          .first
          .toLowerCase();
      if (localeLanguage == normalized) return localeId;
    }
    return null;
  }
}
