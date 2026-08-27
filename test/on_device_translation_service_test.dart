import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/mlkit/on_device_translation_service.dart';

void main() {
  test('translation failure diagnostics expose only the native error code', () {
    final detail = OnDeviceTranslationService.failureDetail(
      const PlatformException(
        code: 'MODEL_DOWNLOAD_FAILED',
        message: '/data/user/0/private-model-path',
      ),
    );

    expect(detail, 'رمز ML Kit: MODEL_DOWNLOAD_FAILED.');
    expect(detail, isNot(contains('/data/user/0')));
  });
}
