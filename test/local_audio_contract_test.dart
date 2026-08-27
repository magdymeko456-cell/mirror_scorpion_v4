import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/platform/device_capability_service.dart';
import 'package:mirror_scorpion_v4/core/speech/audio_transcriber_service.dart';
import 'package:mirror_scorpion_v4/core/speech/translated_audio_export_service.dart';
import 'package:mirror_scorpion_v4/core/speech/whisper_model_installer.dart';

void main() {
  group('LocalAudioCompatibilityPolicy', () {
    DeviceCapabilities device({required int ram, required int storage}) =>
        DeviceCapabilities(
          totalRamBytes: ram,
          availableRamBytes: ram ~/ 2,
          availableStorageBytes: storage,
          supportedAbis: const <String>['arm64-v8a'],
        );

    test('permits audio transcription on an 8 GB phone with enough storage', () {
      expect(
        LocalAudioCompatibilityPolicy.evaluate(device(
          ram: LocalAudioCompatibilityPolicy.minimumRamBytes,
          storage: LocalAudioCompatibilityPolicy.minimumFreeStorageBytes,
        )),
        LocalAudioCompatibility.supported,
      );
    });

    test('limits only local audio transcription when RAM is below 8 GB', () {
      expect(
        LocalAudioCompatibilityPolicy.evaluate(device(
          ram: LocalAudioCompatibilityPolicy.minimumRamBytes - 1,
          storage: LocalAudioCompatibilityPolicy.minimumFreeStorageBytes,
        )),
        LocalAudioCompatibility.insufficientMemory,
      );
    });

    test('rejects an unavailable platform resource snapshot', () {
      expect(
        LocalAudioCompatibilityPolicy.evaluate(device(ram: 0, storage: 0)),
        LocalAudioCompatibility.unavailable,
      );
    });
  });

  group('AudioTranscriberService input contract', () {
    test('accepts supported audio formats and rejects unrelated documents', () {
      expect(AudioTranscriberService.supportsPath('/cache/voice.M4A'), isTrue);
      expect(AudioTranscriberService.supportsPath('/cache/voice.wav'), isTrue);
      expect(AudioTranscriberService.supportsPath('/cache/book.pdf'), isFalse);
    });

    test('enforces the published 128 MB file ceiling', () {
      expect(AudioTranscriberService.allowsFileSize(1), isTrue);
      expect(AudioTranscriberService.allowsFileSize(AudioTranscriberService.maxInputBytes), isTrue);
      expect(AudioTranscriberService.allowsFileSize(AudioTranscriberService.maxInputBytes + 1), isFalse);
    });
  });

  test('the model descriptor has a complete SHA-256 integrity value', () {
    final model = WhisperModelDescriptor.baseMultilingual;
    expect(WhisperModelInstaller.isSha256(model.sha256), isTrue);
    expect(model.expectedBytes, 147951465);
    expect(model.fileName, 'ggml-base.bin');
  });

  test('exported translation audio has a safe WAV filename', () {
    final name = TranslatedAudioExportService.fileNameFor(DateTime.utc(2026, 8, 27));
    expect(name, startsWith('mirror-scorpion-translated-'));
    expect(TranslatedAudioExportService.isWavPath(name), isTrue);
    expect(TranslatedAudioExportService.isWavPath('voice.mp3'), isFalse);
  });
}
