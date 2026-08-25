import 'package:flutter/foundation.dart';

/// حالة تكامل ElevenLabs من وجهة نظر التطبيق.
///
/// لا تحتوي هذه الطبقة على مفتاح API أو عنوان مزود ولا تنفذ طلبات شبكة.
/// لا يتغير [isGatewayEnabled] إلا بعد نشر خادم وسيط مستقل واعتماد حد تكلفة.
enum ElevenLabsGatewayState { disabledPendingServerApproval }

class ElevenLabsVoiceAttempt {
  const ElevenLabsVoiceAttempt({
    required this.allowed,
    required this.message,
  });

  final bool allowed;
  final String message;
}

class ElevenLabsVoiceService extends ChangeNotifier {
  static const consentDocumentPath =
      'docs/elevenlabs-voice-consent-and-deletion-contract-2026-08-25.md';

  ElevenLabsGatewayState get state =>
      ElevenLabsGatewayState.disabledPendingServerApproval;

  bool get isGatewayEnabled => false;

  String get statusMessage =>
      'ElevenLabs غير مفعّل حالياً: لا يُرسل التطبيق نصاً أو تسجيلاً صوتياً، '
      'ولا يحتوي APK على مفتاح خدمة.';

  Future<ElevenLabsVoiceAttempt> requestCloudReading({
    required String text,
    required String languageCode,
  }) async {
    if (text.trim().isEmpty) {
      return const ElevenLabsVoiceAttempt(
        allowed: false,
        message: 'لا يوجد نص لإرساله إلى القراءة السحابية.',
      );
    }
    return const ElevenLabsVoiceAttempt(
      allowed: false,
      message: 'القراءة السحابية غير مفعّلة بعد. استخدم صوت النظام؛ لم يُرسل '
          'النص إلى ElevenLabs.',
    );
  }

  Future<ElevenLabsVoiceAttempt> requestInstantVoiceClone() async {
    return const ElevenLabsVoiceAttempt(
      allowed: false,
      message: 'نسخ الصوت غير متاح بعد. لن يُرفع أي تسجيل قبل نشر الخادم، '
          'اعتماد حد الاستخدام، وموافقة صريحة لصوت المالك فقط.',
    );
  }
}
