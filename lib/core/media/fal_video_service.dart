import 'package:flutter/foundation.dart';

class FalVideoPreflight {
  const FalVideoPreflight({
    required this.allowed,
    required this.code,
    required this.message,
  });

  final bool allowed;
  final String code;
  final String message;
}

/// واجهة Fal في التطبيق لا تتصل بالشبكة.
/// يبقى طلب الفيديو في الخادم فقط بعد اعتماد حد مالي ومفتاح وموافقة.
class FalVideoService extends ChangeNotifier {
  static const providerName = 'Fal';
  static const modelId = 'fal-ai/wan-25-preview/text-to-video';
  static const maxDurationSeconds = 5;
  static const resolution = '480p';

  bool get enabled => false;
  bool get externalCallsAllowed => false;

  String get statusMessage =>
      'Fal مُعد كتجربة فيديو قصيرة ($maxDurationSeconds ثوانٍ، $resolution) '
      'لكنه مغلق الآن: لا مفتاح، لا حصة مالية، ولا تُرسل قصة أو صورة خارج الجهاز.';

  FalVideoPreflight prepareStoryVideo({
    required String draft,
    required bool hasExplicitConsent,
  }) {
    if (draft.trim().isEmpty) {
      return const FalVideoPreflight(
        allowed: false,
        code: 'STORY_REQUIRED',
        message: 'اكتب مسودة القصة أولاً قبل طلب فيديو.',
      );
    }
    if (!hasExplicitConsent) {
      return const FalVideoPreflight(
        allowed: false,
        code: 'CONSENT_REQUIRED',
        message: 'أكّد موافقتك الصريحة على إرسال النص المختار قبل أي خدمة فيديو مستقبلية.',
      );
    }
    return FalVideoPreflight(
      allowed: false,
      code: 'GATEWAY_DISABLED',
      message: '$statusMessage لا يمكن إنشاء فيديو أو احتساب تكلفة في هذا الإصدار.',
    );
  }
}
