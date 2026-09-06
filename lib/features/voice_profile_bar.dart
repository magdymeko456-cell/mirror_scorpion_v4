import 'package:flutter/material.dart';

import '../core/speech/local_voice_calibration_service.dart';
import '../core/speech/system_tts_service.dart';

/// شريط الأصوات الموحّد: سلمى/سيف/سما/سارة + «صوتي» (معايرة محلية).
/// لا سحابة: التسجيل والمعايرة والحفظ كلها على الجهاز.
class VoiceProfileBar extends StatefulWidget {
  const VoiceProfileBar({super.key, required this.ttsService});

  final SystemTtsService ttsService;

  @override
  State<VoiceProfileBar> createState() => _VoiceProfileBarState();
}

class _VoiceProfileBarState extends State<VoiceProfileBar> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.ttsService,
      builder: (context, _) {
        final selected = widget.ttsService.selectedProfile;
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final profile in SystemVoiceProfile.values)
                ChoiceChip(
                  label: Text(profile.label),
                  selected: selected == profile,
                  tooltip: profile.styleDescription,
                  onSelected: (_) async {
                    if (profile == SystemVoiceProfile.myVoice) {
                      await _openMyVoiceSheet();
                    } else {
                      await widget.ttsService.selectProfile(profile);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openMyVoiceSheet() async {
    final calibrated = await LocalVoiceCalibrationStore.read();
    if (!mounted) return;
    if (calibrated == null) {
      // أول مرة: افتح المعايرة مباشرة
      await _openCalibrationSheet();
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MyVoiceSheet(ttsService: widget.ttsService),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openCalibrationSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CalibrationSheet(ttsService: widget.ttsService),
    );
    if (mounted) setState(() {});
  }
}

class _MyVoiceSheet extends StatelessWidget {
  const _MyVoiceSheet({required this.ttsService});

  final SystemTtsService ttsService;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('صوتي — معايرة محلية', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'معايرة سرعة ونبرة تعتمد صوت Android المثبت — تقريب لصوتك، '
            'وليست نسخاً كاملاً. كل شيء محلي على جهازك.',
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ttsService.selectProfile(SystemVoiceProfile.myVoice);
            },
            child: const Text('استخدام صوتي'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('إعادة المعايرة'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              await LocalVoiceCalibrationStore.clear();
              await ttsService.selectProfile(SystemVoiceProfile.salma);
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('حذف المعايرة'),
          ),
        ],
      ),
    );
  }
}

class _CalibrationSheet extends StatefulWidget {
  const _CalibrationSheet({required this.ttsService});

  final SystemTtsService ttsService;

  @override
  State<_CalibrationSheet> createState() => _CalibrationSheetState();
}

class _CalibrationSheetState extends State<_CalibrationSheet> {
  final LocalVoiceCalibrationService _service = LocalVoiceCalibrationService();
  String? _samplePath;
  String? _notice;

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted || message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleRecord() async {
    if (_service.isRecording) {
      final path = _samplePath;
      if (path == null) return;
      final calibration = await _service.stopAndCalibrate(path);
      if (calibration == null) {
        _toast('تعذر تحليل التسجيل. جرب تسجيلاً أطول وأوضح (10–30 ثانية).');
        return;
      }
      await LocalVoiceCalibrationStore.save(
        speechRate: calibration.speechRate,
        pitch: calibration.pitch,
      );
      await widget.ttsService.selectProfile(SystemVoiceProfile.myVoice);
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast('تمت المعايرة: سرعة ${(calibration.speechRate * 100).toStringAsFixed(0)}٪');
      return;
    }
    try {
      final path = await _service.startRecording();
      if (path == null) {
        _toast('امنح إذن الميكروفون للتطبيق من إعدادات النظام.');
        return;
      }
      setState(() {
        _samplePath = path;
        _notice = 'جارٍ التسجيل… تحدث بوضوح من 10 إلى 30 ثانية ثم اضغط إيقافاً.';
      });
    } catch (_) {
      _toast('تعذر بدء التسجيل.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('معايرة صوتي — تسجيل قصير', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'سجّل 10–30 ثانية بصوتك الطبيعي. يبقى التسجيل على جهازك '
            'ويُحذف بعد المعايرة. لا يُرفع أي شيء للإنترنت.',
          ),
          const SizedBox(height: 12),
          if (_notice != null) Text(_notice!),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _toggleRecord,
            icon: Icon(_service.isRecording ? Icons.stop : Icons.mic),
            label: Text(_service.isRecording ? 'إيقاف المعايرة' : 'بدء التسجيل'),
          ),
        ],
      ),
    );
  }
}
