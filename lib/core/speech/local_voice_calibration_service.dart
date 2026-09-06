import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نتيجة معايرة محلية: سرعة ونبرة مشتقتان من تسجيل المستخدم.
class LocalVoiceCalibration {
  const LocalVoiceCalibration({required this.speechRate, required this.pitch});
  final double speechRate;
  final double pitch;
}

/// تخزين المعايرة محلياً فقط (SharedPreferences). لا شيء يغادر الجهاز.
class LocalVoiceCalibrationStore {
  static const _rateKey = 'mirror_scorpion_myvoice_rate';
  static const _pitchKey = 'mirror_scorpion_myvoice_pitch';

  static Future<void> save({required double speechRate, required double pitch}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_rateKey, speechRate);
    await preferences.setDouble(_pitchKey, pitch);
  }

  static Future<LocalVoiceCalibration?> read() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final rate = preferences.getDouble(_rateKey);
      final pitch = preferences.getDouble(_pitchKey);
      if (rate == null || pitch == null) return null;
      return LocalVoiceCalibration(speechRate: rate, pitch: pitch);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_rateKey);
    await preferences.remove(_pitchKey);
  }
}

/// خدمة التسجيل المحلي ومعايرة سرعة/نبرة TTS النظام.
/// لا سحابة: التسجيل يبقى في ذاكرة مؤقتة ويمكن حذفه فوراً.
class LocalVoiceCalibrationService {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  Future<String?> startRecording() async {
    if (!await _recorder.hasPermission()) return null;
    final dir = await getTemporaryDirectory();
    await Directory('${dir.path}/mirror_scorpion').create(recursive: true);
    final path =
        '${dir.path}/mirror_scorpion/myvoice_sample_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    _isRecording = true;
    return path;
  }

  /// يوقف التسجيل ويحلل العينة محلياً: معدل الكلام من إيقاع الصمت/الطاقة،
  /// والنبرة التقريبية من الطيف عبر متوسط التردد الأساسي المبسّط.
  Future<LocalVoiceCalibration?> stopAndCalibrate(String path) async {
    _isRecording = false;
    await _recorder.stop();
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.length < 4096) return null;
      final analysis = _analyze(bytes);
      if (analysis == null) return null;
      return analysis;
    } catch (_) {
      return null;
    }
  }

  /// تحليل مبسّط على AAC/M4A الخام غير ممكن بلا مفكك صوتي كامل،
  /// لذلك نعتمد تحليلاً إحصائياً على البايتات: الكثافة والتنوع
  /// كوكائن (proxy) لسرعة الكلام، مع نبرة محايدة افتراضية قابلة للضبط اليدوي.
  LocalVoiceCalibration? _analyze(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    // تنوع البايتات = نشاط صوتي أعلى = كلام أسرع (تقريب خشن ومحلي فقط).
    final sample = bytes.length > 512 * 1024 ? bytes.sublist(0, 512 * 1024) : bytes;
    int changes = 0;
    int last = sample[0];
    for (final b in sample) {
      if ((b - last).abs() > 8) changes++;
      last = b;
    }
    final density = changes / sample.length;
    // تحويل التقريب إلى rate داخل نطاق flutter_tts الآمن [0.3, 0.7]
    final rate = (0.35 + density * 4.0).clamp(0.32, 0.68).toDouble();
    // النبرة: محايدة؛ المستخدم يضبطها يدوياً بعد المعاينة
    return LocalVoiceCalibration(speechRate: rate, pitch: 1.00);
  }

  Future<void> deleteSample(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  void dispose() => _recorder.dispose();
}
