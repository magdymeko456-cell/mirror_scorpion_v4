import 'package:flutter/foundation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

enum OnDeviceTranslationState {
  translated,
  sameLanguage,
  unsupportedPlatform,
  undeterminedSource,
  unsupportedLanguage,
  modelDownloadFailed,
  failed,
}

class OnDeviceTranslationResult {
  const OnDeviceTranslationResult({
    required this.state,
    this.text,
    this.sourceLanguage,
    this.message,
  });

  final OnDeviceTranslationState state;
  final String? text;
  final String? sourceLanguage;
  final String? message;

  bool get isSuccess =>
      state == OnDeviceTranslationState.translated ||
      state == OnDeviceTranslationState.sameLanguage;
}

/// يربط واجهة Flutter بمحرك ML Kit الأصلي فقط. لا ينشئ أي ناتج بديل إذا
/// تعذر تحديد اللغة أو تنزيل النموذج أو تشغيل المنصة الأصلية.
class OnDeviceTranslationService {
  const OnDeviceTranslationService();

  static const Map<String, String> _aliases = <String, String>{
    'iw': 'he',
  };

  static TranslateLanguage? languageForCode(String code) {
    final normalized = _aliases[code.toLowerCase()] ?? code.toLowerCase();
    for (final language in TranslateLanguage.values) {
      if (language.bcpCode.toLowerCase() == normalized) return language;
    }
    return null;
  }

  static bool get isNativePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<OnDeviceTranslationResult> translate({
    required String text,
    required String targetLanguageCode,
    String? sourceLanguageCode,
  }) async {
    final sourceText = text.trim();
    if (!isNativePlatform) {
      return const OnDeviceTranslationResult(
        state: OnDeviceTranslationState.unsupportedPlatform,
        message: 'الترجمة المحلية متاحة على Android وiOS فقط.',
      );
    }
    if (sourceText.length < 3) {
      return const OnDeviceTranslationResult(
        state: OnDeviceTranslationState.undeterminedSource,
        message: 'اكتب نصاً أطول قليلاً ليتمكن المحرك من تحديد اللغة.',
      );
    }

    final identifier = LanguageIdentifier(confidenceThreshold: 0.5);
    try {
      final requestedSourceCode = sourceLanguageCode?.trim().toLowerCase();
      final detectedCode = requestedSourceCode?.isNotEmpty == true
          ? requestedSourceCode!
          : await identifier.identifyLanguage(sourceText);
      if (detectedCode == identifier.undeterminedLanguageCode) {
        return const OnDeviceTranslationResult(
          state: OnDeviceTranslationState.undeterminedSource,
          message: 'لم يتمكن المحرك المحلي من تحديد لغة النص بثقة كافية.',
        );
      }

      final sourceLanguage = languageForCode(detectedCode);
      final targetLanguage = languageForCode(targetLanguageCode);
      if (sourceLanguage == null || targetLanguage == null) {
        return OnDeviceTranslationResult(
          state: OnDeviceTranslationState.unsupportedLanguage,
          sourceLanguage: detectedCode,
          message:
              'لا يدعم ML Kit المحلي حالياً لغة المصدر أو الهدف المختارة. لا توجد ترجمة بديلة.',
        );
      }
      if (sourceLanguage == targetLanguage) {
        return OnDeviceTranslationResult(
          state: OnDeviceTranslationState.sameLanguage,
          text: sourceText,
          sourceLanguage: sourceLanguage.bcpCode,
          message: 'لغة المصدر مطابقة للغة الهدف؛ لم يتغير النص.',
        );
      }

      final modelManager = OnDeviceTranslatorModelManager();
      final sourceReady = await _ensureModel(modelManager, sourceLanguage);
      final targetReady = await _ensureModel(modelManager, targetLanguage);
      if (!sourceReady || !targetReady) {
        return OnDeviceTranslationResult(
          state: OnDeviceTranslationState.modelDownloadFailed,
          sourceLanguage: sourceLanguage.bcpCode,
          message:
              'تعذر تنزيل نموذجَي الترجمة اللازمين. اتصل بالإنترنت أولاً ثم أعد المحاولة.',
        );
      }

      final translator = OnDeviceTranslator(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      try {
        final translated = await translator.translateText(sourceText);
        return OnDeviceTranslationResult(
          state: OnDeviceTranslationState.translated,
          text: translated,
          sourceLanguage: sourceLanguage.bcpCode,
          message: 'تمت الترجمة على الجهاز بعد تجهيز نماذج ML Kit.',
        );
      } finally {
        await translator.close();
      }
    } catch (_) {
      return const OnDeviceTranslationResult(
        state: OnDeviceTranslationState.failed,
        message:
            'تعذرت الترجمة المحلية. تحقق من اتصالك عند تنزيل النموذج ثم أعد المحاولة.',
      );
    } finally {
      await identifier.close();
    }
  }

  Future<bool> _ensureModel(
    OnDeviceTranslatorModelManager modelManager,
    TranslateLanguage language,
  ) async {
    final code = language.bcpCode;
    if (await modelManager.isModelDownloaded(code)) return true;
    return modelManager.downloadModel(code);
  }
}
