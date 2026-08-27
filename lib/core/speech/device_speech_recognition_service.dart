import 'dart:async';

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
  String _requestedLanguageCode = 'ar';

  bool get isListening => _speechToText.isListening;
  bool get isReady => _isReady;
  String? get message => _message;

  Future<bool> start({
    required String languageCode,
    required ValueChanged<String> onText,
  }) async {
    _onText = onText;
    _requestedLanguageCode = languageCode.toLowerCase();
    try {
      if (_speechToText.isListening) {
        if (!await cancelAndWait()) return false;
      }
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
      if (localeId == null) {
        final available = SpeechLocaleResolver.availableLanguageCodes(
          installedLocales.map((locale) => locale.localeId),
        );
        _message = available.isEmpty
            ? 'لا توجد لغة تعرف كلام متاحة في الجهاز. لم يبدأ الاستماع ولم يُستخدم بديل عربي.'
            : 'لغة الكلام «$languageCode» غير متاحة في خدمة التعرف. اللغات المتاحة: ${available.join('، ')}. لم يبدأ الاستماع ولم يُستخدم بديل عربي.';
        notifyListeners();
        return false;
      }
      await _speechToText.listen(
        onResult: _handleResult,
        listenOptions: stt.SpeechListenOptions(localeId: localeId),
      );
      _message = 'استمع الآن بلغة الكلام «$languageCode» ($localeId)؛ سيظهر النص المعترف به في محرر المصدر.';
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

  /// يحسم الجلسة القائمة ضمن مهلة صغيرة قبل اختيار locale جديد. لا تبدأ
  /// الواجهة الاستماع بلغة مقابلة فوق جلسة ما زالت Android توقفها.
  Future<bool> stopAndWait({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    await stop();
    return _waitUntilStopped(timeout: timeout);
  }

  /// ينهي الجلسة الحالية فوراً قبل بدء لغة مايك مختلفة. نستخدم cancel بدلاً
  /// من stop عند تبديل المتحدث حتى لا يحاول Android إنهاء تسجيل اللغة السابقة
  /// بالتوازي مع طلب لغة جديدة.
  Future<bool> cancelAndWait({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (!_isReady && !_speechToText.isListening) return true;
    try {
      await _speechToText.cancel();
    } catch (_) {
      _message = 'تعذر إلغاء جلسة تعرف الكلام السابقة.';
      notifyListeners();
      return false;
    }
    return _waitUntilStopped(timeout: timeout);
  }

  Future<bool> _waitUntilStopped({required Duration timeout}) async {
    final deadline = DateTime.now().add(timeout);
    while (_speechToText.isListening && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    if (_speechToText.isListening) {
      _message = 'لم تنته جلسة تعرف الكلام السابقة بعد. انتظر لحظات ثم أعد تشغيل المايك.';
      notifyListeners();
      return false;
    }
    return true;
  }

  void _handleResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.trim();
    if (text.isEmpty) return;
    if (SpeechRecognitionScriptGuard.rejectsArabicFallback(
      expectedLanguageCode: _requestedLanguageCode,
      recognizedText: text,
    )) {
      _message = 'أعادت خدمة الجهاز نصاً عربياً رغم اختيار «$_requestedLanguageCode». لم يُرسل النص إلى الترجمة؛ ثبّت لغة الكلام المطلوبة في إعدادات التعرف الصوتي ثم أعد المحاولة.';
      notifyListeners();
      return;
    }
    _onText?.call(text);
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

/// يطابق لغة المصدر مع لغة تعرف مثبّتة على الهاتف. لا يسمح للواجهة بالرجوع
/// بصمت إلى لغة النظام عندما لا تتوفر مطابقة صريحة.
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

  static List<String> availableLanguageCodes(Iterable<String> installedLocaleIds) {
    return installedLocaleIds
        .map(
          (localeId) => localeId
              .replaceAll('_', '-')
              .split('-')
              .first
              .toLowerCase(),
        )
        .toSet()
        .toList()
      ..sort();
  }
}

/// يمنع تمرير ناتج معروف بأنه تعريب نطقي للإنجليزية إلى مترجم الإنجليزية.
/// هذا حارس شفاف لحالة القبول المبلغ عنها، وليس كاشف لغة عام أو أداة ذكاء.
class SpeechRecognitionScriptGuard {
  const SpeechRecognitionScriptGuard._();

  static const _latinScriptLanguages = <String>{
    'af', 'ca', 'cs', 'da', 'de', 'en', 'es', 'et', 'eu', 'fi', 'fr', 'ga',
    'gl', 'hr', 'hu', 'id', 'is', 'it', 'lt', 'lv', 'ms', 'nl', 'no', 'pl',
    'pt', 'ro', 'sk', 'sl', 'sq', 'sv', 'sw', 'tl', 'tr', 'vi', 'zu',
  };

  static bool rejectsArabicFallback({
    required String expectedLanguageCode,
    required String recognizedText,
  }) {
    if (!_latinScriptLanguages.contains(expectedLanguageCode.toLowerCase())) {
      return false;
    }
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(recognizedText);
    final hasLatin = RegExp(r'[A-Za-z]').hasMatch(recognizedText);
    return hasArabic && !hasLatin;
  }
}
