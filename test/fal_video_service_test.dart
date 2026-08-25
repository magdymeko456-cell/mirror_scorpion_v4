import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/media/fal_video_service.dart';

void main() {
  test('Fal video gateway stays disabled in Flutter', () {
    final service = FalVideoService();

    expect(service.enabled, isFalse);
    expect(service.externalCallsAllowed, isFalse);
    expect(service.modelId, 'fal-ai/wan-25-preview/text-to-video');
    expect(service.maxDurationSeconds, 5);
    expect(service.resolution, '480p');
  });

  test('Fal video requires a draft and explicit consent before disabled state', () {
    final service = FalVideoService();

    expect(
      service.prepareStoryVideo(draft: '', hasExplicitConsent: true).code,
      'STORY_REQUIRED',
    );
    expect(
      service.prepareStoryVideo(draft: 'قصة هادفة', hasExplicitConsent: false).code,
      'CONSENT_REQUIRED',
    );
    expect(
      service.prepareStoryVideo(draft: 'قصة هادفة', hasExplicitConsent: true).code,
      'GATEWAY_DISABLED',
    );
  });
}
