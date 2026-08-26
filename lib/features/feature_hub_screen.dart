import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app/royal_dark_theme.dart';
import '../core/localization/language_preferences.dart';
import '../core/content/offline_content_storage.dart';
import '../core/content/github_content_catalog_service.dart';
import '../core/games/chess_game_controller.dart';
import '../core/inspiration/inspiration_safety.dart';
import '../core/documents/local_document_text_service.dart';
import '../core/media/runware_video_service.dart';
import '../core/mlkit/on_device_ocr_service.dart';
import '../core/mlkit/on_device_translation_service.dart';
import '../core/platform/android_overlay_service.dart';
import '../core/pro/premium_verification_service.dart';
import '../core/speech/device_speech_recognition_service.dart';
import '../core/speech/elevenlabs_voice_service.dart';
import '../core/speech/system_tts_service.dart';
import 'subscription_boundaries_card.dart';

enum FeatureKind { translation, dialogue, documents, stories, games, settings }

abstract final class TranslationLanguageCatalog {
  static const labels = <String, String>{
    'af': 'Afrikaans', 'sq': 'Shqip', 'am': 'አማርኛ', 'ar': 'العربية', 'hy': 'Հայերեն', 'az': 'Azərbaycan',
    'eu': 'Euskara', 'be': 'Беларуская', 'bn': 'বাংলা', 'bs': 'Bosanski', 'bg': 'Български', 'ca': 'Català',
    'ceb': 'Cebuano', 'ny': 'Chichewa', 'zh': '中文', 'co': 'Corsu', 'hr': 'Hrvatski', 'cs': 'Čeština',
    'da': 'Dansk', 'nl': 'Nederlands', 'en': 'English', 'eo': 'Esperanto', 'et': 'Eesti', 'tl': 'Filipino',
    'fi': 'Suomi', 'fr': 'Français', 'fy': 'Frysk', 'gl': 'Galego', 'ka': 'ქართული', 'de': 'Deutsch',
    'el': 'Ελληνικά', 'gu': 'ગુજરાતી', 'ht': 'Kreyòl', 'ha': 'Hausa', 'haw': 'Hawaiʻi', 'iw': 'עברית',
    'hi': 'हिन्दी', 'hmn': 'Hmong', 'hu': 'Magyar', 'is': 'Íslenska', 'ig': 'Igbo', 'id': 'Bahasa Indonesia',
    'ga': 'Gaeilge', 'it': 'Italiano', 'ja': '日本語', 'jw': 'Basa Jawa', 'kn': 'ಕನ್ನಡ', 'kk': 'Қазақ',
    'km': 'ខ្មែរ', 'rw': 'Kinyarwanda', 'ko': '한국어', 'ku': 'Kurdî', 'ky': 'Кыргызча', 'lo': 'ລາວ',
    'la': 'Latina', 'lv': 'Latviešu', 'lt': 'Lietuvių', 'lb': 'Lëtzebuergesch', 'mk': 'Македонски',
    'mg': 'Malagasy', 'ms': 'Bahasa Melayu', 'ml': 'മലയാളം', 'mt': 'Malti', 'mi': 'Māori', 'mr': 'मराठी',
    'mn': 'Монгол', 'my': 'မြန်မာ', 'ne': 'नेपाली', 'no': 'Norsk', 'or': 'ଓଡ଼ିଆ', 'ps': 'پښتو',
    'fa': 'فارسی', 'pl': 'Polski', 'pt': 'Português', 'pa': 'ਪੰਜਾਬੀ', 'ro': 'Română', 'ru': 'Русский',
    'sm': 'Samoa', 'gd': 'Gàidhlig', 'sr': 'Српски', 'st': 'Sesotho', 'sn': 'Shona', 'sd': 'سنڌي',
    'si': 'සිංහල', 'sk': 'Slovenčina', 'sl': 'Slovenščina', 'so': 'Soomaali', 'es': 'Español', 'su': 'Basa Sunda',
    'sw': 'Kiswahili', 'sv': 'Svenska', 'tg': 'Тоҷикӣ', 'ta': 'தமிழ்', 'tt': 'Татар', 'te': 'తెలుగు',
    'th': 'ไทย', 'tr': 'Türkçe', 'tk': 'Türkmen', 'ug': 'ئۇيغۇرچە', 'uk': 'Українська', 'ur': 'اردو',
    'uz': "O'zbek", 'vi': 'Tiếng Việt', 'cy': 'Cymraeg', 'xh': 'isiXhosa', 'yi': 'יידיש', 'yo': 'Yorùbá', 'zu': 'isiZulu',
  };
}

String _translationProgressMessage(OnDeviceTranslationProgress progress) =>
    switch (progress) {
      OnDeviceTranslationProgress.identifyingLanguage =>
        'جارٍ تحديد لغة النص…',
      OnDeviceTranslationProgress.checkingModels =>
        'جارٍ فحص نماذج اللغة المحلية…',
      OnDeviceTranslationProgress.downloadingModels =>
        'يُنزّل التطبيق نموذجَي اللغة لأول مرة؛ قد يستغرق ذلك أكثر من 3 ثوانٍ حسب الشبكة…',
      OnDeviceTranslationProgress.translating =>
        'جارٍ إجراء الترجمة على الجهاز…',
    };

class FeatureHubScreen extends StatelessWidget {
  const FeatureHubScreen({required this.kind, super.key});

  final FeatureKind kind;

  @override
  Widget build(BuildContext context) {
    final child = switch (kind) {
      FeatureKind.translation => const _TranslationPanel(),
      FeatureKind.dialogue => const _DialoguePanel(),
      FeatureKind.documents => const _DocumentsPanel(),
      FeatureKind.stories => const _StoriesPanel(),
      FeatureKind.games => const _GamesPanel(),
      FeatureKind.settings => const _SettingsPanel(),
    };
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(appBar: AppBar(title: Text(_titleFor(kind))), body: child),
    );
  }

  String _titleFor(FeatureKind value) => switch (value) {
        FeatureKind.translation => 'الترجمة النصية',
        FeatureKind.dialogue => 'الحوار المترجم',
        FeatureKind.documents => 'المستندات والعدسة',
        FeatureKind.stories => 'القصص والإلهام',
        FeatureKind.games => 'ساحة الألعاب',
        FeatureKind.settings => 'الإعدادات وPRO',
      };
}

class _TranslationPanel extends StatefulWidget {
  const _TranslationPanel();

  @override
  State<_TranslationPanel> createState() => _TranslationPanelState();
}

class _TranslationPanelState extends State<_TranslationPanel> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  final _translationService = const OnDeviceTranslationService();
  final _speechService = SystemTtsService();
  final _recognitionService = DeviceSpeechRecognitionService();
  String _selectedLanguage = 'ar';
  String? _notice;
  bool _hasCompletedTranslation = false;
  bool _isTranslating = false;
  bool _loadedLanguagePreference = false;
  Timer? _translationDebounce;
  @override
  void initState() {
    super.initState();
    _speechService.addListener(_onSpeechChanged);
    _speechService.initialize();
    _recognitionService.addListener(_onSpeechChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedLanguagePreference) {
      final preferences = context.read<LanguagePreferences>();
      final savedTarget = preferences.translationTargetLanguage;
      if (TranslationLanguageCatalog.labels.containsKey(savedTarget)) {
        _selectedLanguage = savedTarget;
      }
      _loadedLanguagePreference = true;
    }
  }

  Future<void> _selectLanguage(String code) async {
    setState(() => _selectedLanguage = code);
    await context.read<LanguagePreferences>().setTranslationTargetLanguage(code);
    _queueTranslation(_input.text);
  }

  void _onSpeechChanged() {
    if (mounted) setState(() {});
  }

  void _beginFreshTranslationIfNeeded() {
    if (!_hasCompletedTranslation) return;
    setState(() {
      _input.clear();
      _output.clear();
      _notice = 'بدأت جلسة ترجمة جديدة.';
      _hasCompletedTranslation = false;
    });
  }

  Future<void> _speakTranslation() async {
    if (_speechService.isSpeaking) {
      await _speechService.stop();
      return;
    }
    await _speechService.speak(
      text: _output.text,
      languageCode: _selectedLanguage,
    );
    if (mounted && _speechService.message != null) {
      setState(() => _notice = _speechService.message);
    }
  }

  Future<void> _toggleMicrophone() async {
    if (_recognitionService.isListening) {
      await _recognitionService.stop();
      if (mounted && _recognitionService.message != null) {
        setState(() => _notice = _recognitionService.message);
      }
      return;
    }
    final sourceLanguage = context.read<LanguagePreferences>().deviceLanguageCode;
    await _speechService.stop();
    if (!mounted) return;
    _beginFreshTranslationIfNeeded();
    await _recognitionService.start(
      languageCode: sourceLanguage,
      onText: (recognizedText) {
        if (!mounted) return;
        _input.text = recognizedText;
        _queueTranslation(
          recognizedText,
          sourceLanguageCode: sourceLanguage,
        );
      },
    );
    if (mounted && _recognitionService.message != null) {
      setState(() => _notice = _recognitionService.message);
    }
  }

  Future<void> _pickAudioFile() async {
    final file = await FilePicker.pickFile(type: FileType.audio);
    if (!mounted) return;
    if (file == null) {
      setState(() => _notice = 'لم يتم اختيار ملف صوت.');
      return;
    }
    setState(() {
      _notice = 'تم اختيار «${file.name}» محلياً. لن يُرفع أو يُفرّغ قبل تشغيل خدمة الصوت الحية وموافقتك الصريحة.';
    });
  }

  void _showUnavailableAction(String action) {
    setState(() => _notice = '$action يحتاج خدمة صوت أو ملفات منفصلة؛ لم يتم إنشاء ناتج بديل.');
  }

  void _queueTranslation(String value, {String? sourceLanguageCode}) {
    _translationDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _output.clear();
        _notice = null;
        _isTranslating = false;
      });
      return;
    }
    _translationDebounce = Timer(const Duration(milliseconds: 650), () {
      _translateLocally(value, sourceLanguageCode: sourceLanguageCode);
    });
  }

  Future<void> _translateLocally(
    String value, {
    String? sourceLanguageCode,
  }) async {
    if (!mounted || value.trim() != _input.text.trim()) return;
    setState(() {
      _isTranslating = true;
      _notice = sourceLanguageCode == null
          ? 'جارٍ تحديد لغة النص وتجهيز نموذج الترجمة المحلي…'
          : 'جارٍ تجهيز نموذج الترجمة المحلي للغة الميكروفون…';
    });
    final result = await _translationService.translate(
      text: value,
      targetLanguageCode: _selectedLanguage,
      sourceLanguageCode: sourceLanguageCode,
      onProgress: (progress) {
        if (mounted && value.trim() == _input.text.trim()) {
          setState(() => _notice = _translationProgressMessage(progress));
        }
      },
    );
    if (!mounted || value.trim() != _input.text.trim()) return;
    setState(() {
      _isTranslating = false;
      if (result.isSuccess) _output.text = result.text ?? '';
      if (!result.isSuccess) _output.clear();
      _hasCompletedTranslation =
          result.isSuccess && _output.text.trim().isNotEmpty;
      _notice = result.message;
    });
  }

  @override
  void dispose() {
    _translationDebounce?.cancel();
    _speechService.removeListener(_onSpeechChanged);
    _speechService.stop();
    _recognitionService.removeListener(_onSpeechChanged);
    _recognitionService.dispose();
  _input.dispose();
  _output.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
    final deviceLanguage = context.watch<LanguagePreferences>().deviceLanguageCode;
return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: _TranslationLanguageMenu(
              value: _selectedLanguage,
              label: 'لغة الترجمة',
              icon: Icons.translate,
              onChanged: _selectLanguage,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: _DeviceSpeechLanguageLabel(
              languageCode: deviceLanguage,
              label: 'لغة المايك — من الجهاز',
            ),
          ),
        ),
        const SizedBox(height: 10),
        _TranslationEditor(
          controller: _input,
          hint: 'ابدأ بالكتابة أو اضغط المايك للتحدث...',
          readOnly: false,
          actionsOnRight: false,
          onTap: _beginFreshTranslationIfNeeded,
          onChanged: (value) => _queueTranslation(
            value,
            sourceLanguageCode: deviceLanguage,
          ),
          actions: [
            _EditorAction(
              icon: _recognitionService.isListening ? Icons.stop_circle_outlined : Icons.mic,
              tooltip: _recognitionService.isListening ? 'إيقاف التقاط الكلام' : 'التقاط الكلام من ميكروفون الجهاز',
              onPressed: _toggleMicrophone,
            ),
            _EditorAction(
              icon: Icons.attach_file,
              tooltip: 'اختيار ملف صوتي لترجمته',
              onPressed: _pickAudioFile,
            ),
          ],
        ),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                if (_isTranslating)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(end: 8),
                    child: SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Expanded(child: Text(_notice!, style: const TextStyle(color: RoyalColors.gold))),
              ],
            ),
          ),
        const SizedBox(height: 10),
        _TranslationEditor(
          controller: _output,
          hint: 'ستظهر ترجمة ML Kit المحلية هنا بعد تنزيل النماذج.',
          readOnly: true,
          actionsOnRight: true,
          actions: [
            _EditorAction(icon: _speechService.isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up, tooltip: _speechService.isSpeaking ? 'إيقاف النطق' : 'نطق الترجمة بصوت النظام', onPressed: _speakTranslation),
            _EditorAction(icon: Icons.share, tooltip: 'مشاركة ملف صوت مترجم', onPressed: () => _showUnavailableAction('مشاركة ملف صوت مترجم')),
            _EditorAction(icon: Icons.copy, tooltip: 'نسخ الترجمة', onPressed: () async {
              if (_output.text.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لا يوجد نص مترجم لنسخه بعد.')),
                  );
                }
                return;
              }
              await Clipboard.setData(ClipboardData(text: _output.text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ الترجمة.')),
                );
              }
            }),
          ],
        ),
      ],
    );
  }
}

class _TranslationLanguageMenu extends StatelessWidget {
  const _TranslationLanguageMenu({
    required this.value,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  final String value;
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.cyanAccent),
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(color: RoyalColors.muted, fontSize: 11)),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1B2838),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.cyanAccent),
              items: TranslationLanguageCatalog.labels.entries
                  .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (code) {
                if (code != null) onChanged(code);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceSpeechLanguageLabel extends StatelessWidget {
  const _DeviceSpeechLanguageLabel({
    required this.languageCode,
    required this.label,
  });

  final String languageCode;
  final String label;

  @override
  Widget build(BuildContext context) {
    final languageLabel =
        TranslationLanguageCatalog.labels[languageCode] ?? languageCode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic_none, size: 14, color: Colors.cyanAccent),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: RoyalColors.muted, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            languageLabel,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TranslationEditor extends StatelessWidget {
  const _TranslationEditor({
    required this.controller,
    required this.hint,
    required this.readOnly,
    required this.actions,
    required this.actionsOnRight,
    this.onTap,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final List<_EditorAction> actions;
  final bool actionsOnRight;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Stack(
        children: [
          TextField(
            controller: controller,
            readOnly: readOnly,
            expands: true,
            minLines: null,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(color: Colors.white, fontSize: 17),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(bottom: 56),
            ),
            onTap: onTap,
            onChanged: onChanged,
          ),
          Positioned(
            bottom: 0,
            left: actionsOnRight ? null : 0,
            right: actionsOnRight ? 0 : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: actions
                  .map(
                    (action) => IconButton(
                      tooltip: action.tooltip,
                      onPressed: action.onPressed,
                      icon: Icon(action.icon, color: Colors.cyanAccent),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorAction {
  const _EditorAction({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
}

class _DialoguePanel extends StatefulWidget {
  const _DialoguePanel();

  @override
  State<_DialoguePanel> createState() => _DialoguePanelState();
}

class _DialoguePanelState extends State<_DialoguePanel> {
  final _source = TextEditingController();
  final _translated = TextEditingController();
  final _translationService = const OnDeviceTranslationService();
  final _recognitionService = DeviceSpeechRecognitionService();
  final _speechService = SystemTtsService();
  Timer? _translationDebounce;
  String _leftTargetLanguage = 'en';
  String? _notice;
  bool _hasCompletedDialogueTranslation = false;
  bool _isTranslating = false;
  bool _loadedLanguagePreferences = false;

  @override
  void initState() {
    super.initState();
    _recognitionService.addListener(_onServiceChanged);
    _speechService.addListener(_onServiceChanged);
    _speechService.initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedLanguagePreferences) return;
    final preferences = context.read<LanguagePreferences>();
    _leftTargetLanguage = preferences.translationTargetLanguage;
    _loadedLanguagePreferences = true;
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  void _beginFreshDialogueIfNeeded() {
    if (!_hasCompletedDialogueTranslation) return;
    setState(() {
      _source.clear();
      _translated.clear();
      _notice = 'بدأت جلسة حوار جديدة.';
      _hasCompletedDialogueTranslation = false;
    });
  }

  Future<void> _selectLeftTargetLanguage(String code) async {
    final preferences = context.read<LanguagePreferences>();
    final sourceLanguage = preferences.deviceLanguageCode;
    setState(() => _leftTargetLanguage = code);
    await preferences.setTranslationTargetLanguage(code);
    if (!mounted) return;
    _queueTranslation(
      _source.text,
      sourceLanguageCode: sourceLanguage,
    );
  }

  Future<void> _toggleMicrophone() async {
    if (_recognitionService.isListening) {
      await _recognitionService.stop();
      if (mounted && _recognitionService.message != null) {
        setState(() => _notice = _recognitionService.message);
      }
      return;
    }
    final sourceLanguage = context.read<LanguagePreferences>().deviceLanguageCode;
    await _speechService.stop();
    if (!mounted) return;
    _beginFreshDialogueIfNeeded();
    await _recognitionService.start(
      languageCode: sourceLanguage,
      onText: (recognizedText) {
        if (!mounted) return;
        _source.text = recognizedText;
        _queueTranslation(
          recognizedText,
          sourceLanguageCode: sourceLanguage,
        );
      },
    );
    if (mounted && _recognitionService.message != null) {
      setState(() => _notice = _recognitionService.message);
    }
  }

  void _queueTranslation(String value, {String? sourceLanguageCode}) {
    _translationDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _translated.clear();
        _notice = null;
        _isTranslating = false;
      });
      return;
    }
    _translationDebounce = Timer(const Duration(milliseconds: 650), () {
      _translateDialogue(value, sourceLanguageCode: sourceLanguageCode);
    });
  }

  Future<void> _translateDialogue(
    String value, {
    String? sourceLanguageCode,
  }) async {
    if (!mounted || value.trim() != _source.text.trim()) return;
    final targetLanguage = _leftTargetLanguage;
    setState(() {
      _isTranslating = true;
      _notice = 'جارٍ تجهيز ترجمة الحوار المحلية…';
    });
    final result = await _translationService.translate(
      text: value,
      targetLanguageCode: targetLanguage,
      sourceLanguageCode:
          sourceLanguageCode ?? context.read<LanguagePreferences>().deviceLanguageCode,
      onProgress: (progress) {
        if (mounted && value.trim() == _source.text.trim()) {
          setState(() => _notice = _translationProgressMessage(progress));
        }
      },
    );
    if (!mounted || value.trim() != _source.text.trim() || targetLanguage != _leftTargetLanguage) return;
    setState(() {
      _isTranslating = false;
      _translated.text = result.isSuccess ? result.text ?? '' : '';
      _hasCompletedDialogueTranslation =
          result.isSuccess && _translated.text.trim().isNotEmpty;
      _notice = result.message;
    });
  }

  Future<void> _speakTranslatedText() async {
    if (_speechService.isSpeaking) {
      await _speechService.stop();
      return;
    }
    await _speechService.speak(
      text: _translated.text,
      languageCode: _leftTargetLanguage,
    );
    if (mounted && _speechService.message != null) {
      setState(() => _notice = _speechService.message);
    }
  }

  Future<void> _pickDialogueAudioFile() async {
    final file = await FilePicker.pickFile(type: FileType.audio);
    if (!mounted) return;
    setState(() {
      _notice = file == null
          ? 'لم يتم اختيار ملف صوت.'
          : 'تم اختيار «${file.name}» لمصدر الحوار. التفريغ والترجمة ينتظران خدمة صوت حية؛ لا توجد نتيجة بديلة مصطنعة.';
    });
  }

  @override
  void dispose() {
    _translationDebounce?.cancel();
    _recognitionService.removeListener(_onServiceChanged);
    _recognitionService.dispose();
    _speechService.removeListener(_onServiceChanged);
    _speechService.stop();
    _source.dispose();
    _translated.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceLanguage = context.watch<LanguagePreferences>().deviceLanguageCode;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      children: [
        _DialogueEditor(
          controller: _source,
          label: 'المحرر العلوي — لغة الجهاز',
          hint: 'اكتب أو اضغط الميكروفون ليسمع لغة جهازك…',
          actions: [
            _EditorAction(
              icon: Icons.attach_file,
              tooltip: 'اختيار ملف صوت لمصدر الحوار',
              onPressed: _pickDialogueAudioFile,
            ),
          ],
          onTap: _beginFreshDialogueIfNeeded,
          onChanged: (value) => _queueTranslation(
            value,
            sourceLanguageCode: deviceLanguage,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2838),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.35)),
          ),
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              Expanded(
                child: _DialogueLanguageMenu(
                  value: _leftTargetLanguage,
                  label: 'لغة الترجمة — يسار',
                  onChanged: _selectLeftTargetLanguage,
                ),
              ),
              GestureDetector(
                onTap: _toggleMicrophone,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _recognitionService.isListening
                        ? Colors.redAccent
                        : Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _recognitionService.isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DeviceSpeechLanguageLabel(
                  languageCode: deviceLanguage,
                  label: 'لغة المايك — من الجهاز',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _DialogueEditor(
          controller: _translated,
          label: 'المحرر السفلي — ترجمة الهدف',
          hint: 'ستظهر ترجمة الحوار المحلية هنا…',
          readOnly: true,
          actions: [
            _EditorAction(
              icon: _speechService.isSpeaking
                  ? Icons.stop_circle_outlined
                  : Icons.volume_up,
              tooltip: _speechService.isSpeaking ? 'إيقاف النطق' : 'نطق ترجمة الحوار',
              onPressed: _speakTranslatedText,
            ),
            _EditorAction(
              icon: Icons.copy,
              tooltip: 'نسخ ترجمة الحوار',
              onPressed: () async {
                if (_translated.text.isNotEmpty) {
                  await Clipboard.setData(ClipboardData(text: _translated.text));
                }
              },
            ),
          ],
        ),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                if (_isTranslating)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(end: 8),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                Expanded(child: Text(_notice!, style: const TextStyle(color: RoyalColors.gold))),
              ],
            ),
          ),
      ],
    );
  }
}

class _DialogueLanguageMenu extends StatelessWidget {
  const _DialogueLanguageMenu({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final String value;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(color: RoyalColors.muted, fontSize: 10)),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF1B2838),
            items: TranslationLanguageCatalog.labels.entries
                .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (code) {
              if (code != null) onChanged(code);
            },
          ),
        ),
      ],
    );
  }
}

class _DialogueEditor extends StatelessWidget {
  const _DialogueEditor({
    required this.controller,
    required this.label,
    required this.hint,
    required this.actions,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final List<_EditorAction> actions;
  final bool readOnly;
  final GestureTapCallback? onTap;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(color: RoyalColors.teal, fontSize: 12)),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              expands: true,
              minLines: null,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(color: Colors.white, fontSize: 17),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white30),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 12),
              ),
              onTap: onTap,
              onChanged: onChanged,
            ),
          ),
          if (actions.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions
                  .map((action) => IconButton(
                        tooltip: action.tooltip,
                        onPressed: action.onPressed,
                        icon: Icon(action.icon, color: Colors.cyanAccent),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _DocumentsPanel extends StatefulWidget {
  const _DocumentsPanel();

  @override
  State<_DocumentsPanel> createState() => _DocumentsPanelState();
}

class _DocumentsPanelState extends State<_DocumentsPanel> {
  final _picker = ImagePicker();
  final _ocrService = const OnDeviceOcrService();
  final _documentTextService = const LocalDocumentTextService();
  final _translationService = const OnDeviceTranslationService();
  bool _isScanning = false;
  bool _isTranslating = false;
  String? _selectedFileName;
  String? _selectedDocumentName;
  String? _extractedText;
  String? _translatedText;
  String? _notice;

  Future<void> _scanImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1920,
    );
    if (image == null) {
      if (mounted) setState(() => _notice = 'لم يتم اختيار صورة.');
      return;
    }
    final stopwatch = Stopwatch()..start();
    setState(() {
      _isScanning = true;
      _selectedFileName = image.name;
      _extractedText = null;
      _translatedText = null;
      _notice = 'جارٍ فحص الصورة محلياً…';
    });
    final result = await _ocrService.recognizeImagePath(image.path);
    final remaining = const Duration(seconds: 3) - stopwatch.elapsed;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _extractedText = result.isSuccess ? result.text : null;
      _notice = result.message;
    });
    final extractedText = result.isSuccess ? result.text : null;
    if (extractedText != null && extractedText.trim().isNotEmpty) {
      await _translateExtractedText(extractedText);
    }
  }

  Future<void> _translateExtractedText(String text) async {
    if (!mounted) return;
    final targetLanguage = DocumentTranslationPolicy.targetForDevice(
      context.read<LanguagePreferences>().deviceLanguageCode,
    );
    setState(() {
      _isTranslating = true;
      _translatedText = null;
      _notice = 'جارٍ اكتشاف لغة المستند وترجمته إلى لغة جهازك: '
          '${TranslationLanguageCatalog.labels[targetLanguage] ?? targetLanguage}…';
    });
    final result = await _translationService.translate(
      text: text,
      targetLanguageCode: targetLanguage,
      onProgress: (progress) {
        if (mounted && text == _extractedText) {
          setState(() => _notice = _translationProgressMessage(progress));
        }
      },
    );
    if (!mounted || text != _extractedText) return;
    setState(() {
      _isTranslating = false;
      _translatedText = result.isSuccess ? result.text : null;
      _notice = result.message;
    });
  }

  Future<void> _pickLocalDocument() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'txt'],
    );
    if (!mounted) return;
    if (file == null) {
      setState(() => _notice = 'لم يتم اختيار مستند.');
      return;
    }
    final path = file.path;
    if (path == null || path.isEmpty) {
      setState(() => _notice = 'تعذر الوصول إلى المستند محلياً من هذا الموفر.');
      return;
    }
    setState(() {
      _isScanning = true;
      _selectedDocumentName = file.name;
      _extractedText = null;
      _translatedText = null;
      _notice = 'جارٍ قراءة «${file.name}» محلياً…';
    });
    final result = await _documentTextService.extract(
      path: path,
      fileName: file.name,
    );
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _extractedText = result.isSuccess ? result.text : null;
      _notice = result.message;
    });
    if (result.isSuccess && result.text != null && result.text!.trim().isNotEmpty) {
      await _translateExtractedText(result.text!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const _SectionNotice(title: 'عدسة وPDF ومستندات محلية', detail: 'تستخرج العدسة أو المستند النص محلياً، ثم تكتشف لغته وتترجمه دائماً إلى لغة جهازك. لا توجد لغة هدف قابلة للتغيير في هذا القسم.'),
        const SizedBox(height: 20),
        _DeviceSpeechLanguageLabel(
          languageCode: context.watch<LanguagePreferences>().deviceLanguageCode,
          label: 'الترجمة إلى لغة جهازك',
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: RoyalColors.gold),
            title: const Text('عدسة ذكية'),
            subtitle: const Text('التقاط صورة وفحص النص محلياً'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _isScanning ? null : () => _scanImage(ImageSource.camera),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: RoyalColors.gold),
            title: const Text('اختيار صورة من الجهاز'),
            subtitle: const Text('OCR محلي ثم ترجمة إلى لغة جهازك'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _isScanning ? null : () => _scanImage(ImageSource.gallery),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined, color: RoyalColors.gold),
            title: const Text('اختيار PDF أو ملف نصي محلي'),
            subtitle: Text(_selectedDocumentName == null ? 'PDF نصي أو TXT: استخراج محلي ثم ترجمة إلى لغة جهازك' : 'المستند المختار: $_selectedDocumentName'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _isScanning || _isTranslating ? null : _pickLocalDocument,
          ),
        ),
        if (_selectedFileName != null)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text('الصورة المختارة: $_selectedFileName', style: const TextStyle(color: RoyalColors.muted)),
          ),
        if (_isScanning || _isTranslating)
          const Padding(
            padding: EdgeInsets.only(top: 18),
            child: LinearProgressIndicator(),
          ),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(_notice!, style: const TextStyle(color: RoyalColors.gold, height: 1.5)),
          ),
        if (_extractedText != null)
          Card(
            margin: const EdgeInsets.only(top: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('النص الأصلي المستخرج', style: TextStyle(color: RoyalColors.muted)),
                  const SizedBox(height: 8),
                  SelectableText(_extractedText!, style: const TextStyle(height: 1.6)),
                ],
              ),
            ),
          ),
        if (_translatedText != null)
          Card(
            margin: const EdgeInsets.only(top: 12),
            color: Colors.blueAccent.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('الترجمة إلى لغة جهازك: ${TranslationLanguageCatalog.labels[context.read<LanguagePreferences>().deviceLanguageCode] ?? context.read<LanguagePreferences>().deviceLanguageCode}', style: const TextStyle(color: RoyalColors.gold)),
                  const SizedBox(height: 8),
                  SelectableText(_translatedText!, style: const TextStyle(height: 1.6)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => _TranslatedTextPreviewPage(
                          originalText: _extractedText ?? '',
                          translatedText: _translatedText!,
                          documentName: _selectedDocumentName ?? _selectedFileName ?? 'نص مستخرج',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.fullscreen_outlined),
                    label: const Text('معاينة الترجمة ملء الشاشة'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TranslatedTextPreviewPage extends StatefulWidget {
  const _TranslatedTextPreviewPage({
    required this.originalText,
    required this.translatedText,
    required this.documentName,
  });

  final String originalText;
  final String translatedText;
  final String documentName;

  @override
  State<_TranslatedTextPreviewPage> createState() =>
      _TranslatedTextPreviewPageState();
}

class _TranslatedTextPreviewPageState
    extends State<_TranslatedTextPreviewPage> {
  bool _translationVisible = false;
  bool _initialDelayComplete = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _initialDelayComplete = true;
          _translationVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.documentName)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'معاينة نص محلي: ليست ملف PDF جديداً ولا تحفظ أو تشارك ملفاً في هذا الإصدار.',
                  style: TextStyle(color: RoyalColors.muted, height: 1.45),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GestureDetector(
                    onLongPressStart: (_) =>
                        setState(() => _translationVisible = false),
                    onLongPressEnd: (_) =>
                        setState(() => _translationVisible = _initialDelayComplete),
                    child: Stack(
                      children: [
                        _PreviewTextSheet(
                          heading: 'النص الأصلي المستخرج',
                          text: widget.originalText,
                          color: const Color(0xFF172334),
                        ),
                        if (_translationVisible)
                          Positioned.fill(
                            child: _PreviewTextSheet(
                              heading: 'الترجمة إلى لغة الجهاز',
                              text: widget.translatedText,
                              color: const Color(0xFF23364F),
                              showSignature: true,
                            ),
                          )
                        else
                          const Positioned.fill(
                            child: ColoredBox(
                              color: Color(0x550D1623),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'اضغط مطولاً لرؤية النص الأصلي، ثم ارفع إصبعك للعودة إلى الترجمة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: RoyalColors.gold, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewTextSheet extends StatelessWidget {
  const _PreviewTextSheet({
    required this.heading,
    required this.text,
    required this.color,
    this.showSignature = false,
  });

  final String heading;
  final String text;
  final Color color;
  final bool showSignature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(heading, style: const TextStyle(color: RoyalColors.gold, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                SelectableText(text, style: const TextStyle(fontSize: 17, height: 1.7)),
              ],
            ),
          ),
          if (showSignature)
            Center(
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: -0.48,
                  child: const Opacity(
                    opacity: 0.16,
                    child: Text(
                      'تُرجِم بواسطة ميرور سكربيون',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoriesPanel extends StatefulWidget {
  const _StoriesPanel();

  @override
  State<_StoriesPanel> createState() => _StoriesPanelState();
}

class _StoriesPanelState extends State<_StoriesPanel> {
  final _speechService = SystemTtsService();
  final _contentStorage = const OfflineContentStorage();
  final _moodController = TextEditingController();
  final _storyDraftController = TextEditingController();
  late Future<List<_StoryEntry>> _storiesFuture;
  late Future<List<OfflinePackageRecord>> _packagesFuture;
  String? _notice;
  bool _consentToAi = false;
  bool _consentToRunwareVideo = false;
  bool _threeHourReminder = false;

  @override
  void initState() {
    super.initState();
    _speechService.addListener(_onSpeechChanged);
    _speechService.initialize();
    _storiesFuture = _loadBundledStories();
    _packagesFuture = _contentStorage.listPackages();
  }

  void _onSpeechChanged() {
    if (mounted) setState(() {});
  }

  Future<List<_StoryEntry>> _loadBundledStories() async {
    const assets = <String>[
      'assets/data/starter_original_ar.json',
      'assets/data/owner_inspiration_ar.json',
    ];
    final packages = await Future.wait(
      assets.map((asset) async => jsonDecode(
            await rootBundle.loadString(asset),
          ) as Map<String, dynamic>),
    );
    return packages
        .expand((package) => package['stories'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_StoryEntry.fromJson)
        .toList();
  }

  Future<void> _importContentPackage() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (!mounted || file == null) return;
    try {
      final decoded = jsonDecode(utf8.decode(await file.readAsBytes()));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid root object');
      }
      final packageId = decoded['packageId'] as String?;
      if (packageId == null || packageId.isEmpty) {
        throw const FormatException('Missing packageId');
      }
      await _contentStorage.savePackage(id: packageId, content: decoded);
      if (!mounted) return;
      setState(() {
        _packagesFuture = _contentStorage.listPackages();
        _notice = 'تم حفظ حزمة «$packageId» في مساحة المحتوى المحلية. لا تُعرض كمصدر ديني موثوق ما لم تحمل حقول المصدر والحقوق المناسبة.';
      });
    } on FormatException {
      if (mounted) {
        setState(() => _notice = 'ملف JSON غير صالح كحزمة محتوى. يجب أن يحتوي على packageId وبنية الحزمة المعلنة.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _notice = 'تعذر قراءة أو حفظ حزمة المحتوى المختارة.');
      }
    }
  }

  Future<void> _chooseStoryVoice() async {
    final languageCode = context.read<LanguagePreferences>().storyLanguageCode;
    final voices = await _speechService.voicesForLanguage(languageCode);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0D1623),
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: RadioGroup<SystemTtsVoice>(
            groupValue: _speechService.selectedVoice,
            onChanged: (voice) async {
              await _speechService.selectVoice(
                voice,
                languageCode: languageCode,
              );
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            },
            child: ListView(
              shrinkWrap: true,
              children: [
                const ListTile(
                  title: Text('ملفات الأداء المحلية'),
                  subtitle: Text(
                    'تضبط سرعة وطبقة صوت Android؛ لا تمثل أصواتاً بشرية ثابتة ولا ترفع نصاً أو تسجيلاً.',
                  ),
                ),
                ...SystemVoiceProfile.values.map(
                  (profile) => ListTile(
                    leading: Icon(
                      profile == SystemVoiceProfile.saif
                          ? Icons.record_voice_over_outlined
                          : Icons.volume_up_outlined,
                      color: profile == _speechService.selectedProfile
                          ? RoyalColors.gold
                          : RoyalColors.cyan,
                    ),
                    title: Text(profile.label),
                    subtitle: Text('${profile.styleDescription} • صوت Android المحلي'),
                    trailing: Icon(
                      profile == _speechService.selectedProfile
                          ? Icons.check_circle
                          : Icons.tune_outlined,
                      color: profile == _speechService.selectedProfile
                          ? RoyalColors.gold
                          : RoyalColors.muted,
                    ),
                    onTap: () async {
                      await _speechService.selectProfile(profile);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                ),
                const Divider(),
                const ListTile(
                  title: Text('أصوات النظام المتاحة'),
                  subtitle: Text('يمكنك اختيار صوت Android المثبت المتوافق مع لغة القصة.'),
                ),
                if (voices.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.volume_off_outlined),
                    title: Text('لا يوجد صوت نظام متاح لهذه اللغة'),
                    subtitle: Text('ثبت صوتاً مناسباً من إعدادات Android، ثم أعد المحاولة.'),
                  ),
                ListTile(
                  title: const Text('صوت النظام الافتراضي'),
                  trailing: Icon(
                    _speechService.selectedVoice == null
                        ? Icons.check_circle
                        : Icons.settings_voice_outlined,
                    color: _speechService.selectedVoice == null
                        ? RoyalColors.gold
                        : RoyalColors.muted,
                  ),
                  onTap: () async {
                    await _speechService.selectVoice(
                      null,
                      languageCode: languageCode,
                    );
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
                ...voices.map(
                  (voice) => RadioListTile<SystemTtsVoice>(
                    value: voice,
                    title: Text(voice.name),
                    subtitle: Text(voice.locale),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted && _speechService.message != null) {
      setState(() => _notice = _speechService.message);
    }
  }

  void _openReader(_StoryEntry story) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1623),
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(story.title, style: Theme.of(sheetContext).textTheme.headlineSmall),
                  const SizedBox(height: 14),
                  Text(story.body, style: const TextStyle(height: 1.8, fontSize: 17)),
                  const SizedBox(height: 18),
                  Text('المصدر: ${story.source}', style: const TextStyle(color: RoyalColors.muted)),
                  Text('الإحالة: ${story.citation}', style: const TextStyle(color: RoyalColors.muted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _requestInspiration() {
    final result = InspirationSafety.assessMoodText(_moodController.text);
    setState(() {
      if (result.level == InspirationSafetyLevel.crisis) {
        _notice = result.message;
      } else if (!_consentToAi) {
        _notice = 'للمتابعة إلى خدمة الإلهام الذكية مستقبلاً، فعّل موافقتك الصريحة أولاً. لا تُرسل الكتابة حالياً إلى أي خدمة.';
      } else {
        _notice = '${result.message}\nتم تجهيز طلب محلي فقط. تحتاج الرسالة الذكية الفعلية إلى نشر خدمة خادمية وموديل محدد وسياسة احتفاظ واضحة.';
      }
    });
  }

  void _checkStoryDraft() {
    final result = InspirationSafety.assessStoryDraft(_storyDraftController.text);
    setState(() => _notice = result.message);
  }

  void _prepareRunwareVideo() {
    final safety = InspirationSafety.assessStoryDraft(_storyDraftController.text);
    if (!safety.allowedForDraft) {
      setState(() => _notice = safety.message);
      return;
    }
    final preflight = context.read<RunwareVideoService>().prepareStoryVideo(
          draft: _storyDraftController.text,
          hasExplicitConsent: _consentToRunwareVideo,
        );
    setState(() => _notice = preflight.message);
  }

  @override
  void dispose() {
    _speechService.removeListener(_onSpeechChanged);
    _speechService.stop();
    _moodController.dispose();
    _storyDraftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const _SectionNotice(title: 'قصص وإلهام آمن', detail: 'تبدأ هذه النسخة بحزمة أصلية مرفقة وقارئ داخلي. الفهارس الدينية لا تعرض نصاً حتى يتحقق المصدر والحقوق. يمكن استيراد حزمة JSON محلية إلى مساحة التطبيق؛ أما التنزيل الشبكي وسيناريو الفيديو فيتطلبان خدمات منفصلة.'),
        const SizedBox(height: 12),
        Card(
          color: Colors.blueAccent.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('إلهام اختياري وآمن', style: TextStyle(color: RoyalColors.gold, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('اكتب ما ترغب في مشاركته. لا يقرأ التطبيق رسائلك أو سلوكك في التطبيقات الأخرى، ولا يشخّص حالتك.'),
                const SizedBox(height: 10),
                TextField(
                  controller: _moodController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'مثال: أشعر بتشتت وأحتاج خطوة صغيرة أبدأ بها…'),
                ),
                CheckboxListTile(
                  value: _consentToAi,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('أوافق صراحة على إرسال ما أكتبه إلى خدمة إلهام مستقبلية عندما تُنشر.'),
                  onChanged: (value) => setState(() => _consentToAi = value ?? false),
                ),
                FilledButton.icon(
                  onPressed: _requestInspiration,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('فحص طلب الإلهام'),
                ),
                SwitchListTile(
                  value: _threeHourReminder,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تذكير اختياري كل 3 ساعات'),
                  subtitle: const Text('مغلق افتراضياً؛ يتطلب نشر إشعارات محلية واختبار Android قبل التفعيل.'),
                  onChanged: (value) {
                    setState(() {
                      _threeHourReminder = false;
                      _notice = value
                          ? 'لا يمكن تفعيل التذكير بعد؛ سيتم ربطه بإشعارات محلية صريحة بعد اختبارها.'
                          : 'ظل تذكير الإلهام مغلقاً.';
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('قصة المستخدم إلى فيديو', style: TextStyle(color: RoyalColors.teal, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('تفحص المسودة محلياً أولاً. Runware مختار لمسار فيديو سحابي مستقبلي، لكنه لا ينشئ فيديو ولا يرسل نصاً قبل اعتماد الرصيد والحصة والمفتاح الخادمي.'),
                const SizedBox(height: 10),
                TextField(
                  controller: _storyDraftController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(hintText: 'اكتب مسودة قصتك الهادفة…'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _checkStoryDraft,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('فحص مسودة القصة'),
                ),
                CheckboxListTile(
                  value: _consentToRunwareVideo,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('أوافق على إرسال مسودة القصة المختارة فقط إلى Runware مستقبلاً بعد تفعيل الخدمة.'),
                  subtitle: const Text('لا يشمل ذلك صوراً أو أصواتاً أو قصصاً أخرى، ولا يرسل شيئاً الآن.'),
                  onChanged: (value) => setState(() => _consentToRunwareVideo = value ?? false),
                ),
                Consumer<RunwareVideoService>(
                  builder: (context, runwareVideo, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.lock_outline, color: RoyalColors.gold),
                        title: const Text('Runware: فيديو سحابي — مغلق'),
                        subtitle: Text(runwareVideo.statusMessage),
                      ),
                      FilledButton.icon(
                        onPressed: _prepareRunwareVideo,
                        icon: const Icon(Icons.video_settings_outlined),
                        label: const Text('تحقق من جاهزية Runware'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.folder_copy_outlined, color: RoyalColors.gold),
            title: const Text('استيراد حزمة قصص أو لغة بصيغة JSON'),
            subtitle: const Text('يحفظ الملف في مساحة التطبيق المحلية بعد اختيارك فقط'),
            trailing: const Icon(Icons.file_upload_outlined),
            onTap: _importContentPackage,
          ),
        ),
        FutureBuilder<List<OfflinePackageRecord>>(
          future: _packagesFuture,
          builder: (context, snapshot) {
            final packages = snapshot.data ?? const [];
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                packages.isEmpty
                    ? 'مساحة الحزم المحلية جاهزة؛ لم تُستورد حزمة إضافية بعد.'
                    : 'الحزم المحلية المستوردة: ${packages.map((item) => item.title).join('، ')}',
                style: const TextStyle(color: RoyalColors.muted),
              ),
            );
          },
        ),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_notice!, style: const TextStyle(color: RoyalColors.gold, height: 1.5)),
          ),
        FutureBuilder<List<_StoryEntry>>(
          future: _storiesFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('تعذر تحميل حزمة البداية المحلية.', style: TextStyle(color: Colors.redAccent)),
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Column(
              children: snapshot.data!
                  .map(
                    (story) => Card(
                      child: ListTile(
                        title: Text(story.title),
                        subtitle: Text(story.summary),
                        onTap: () => _openReader(story),
                        trailing: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            IconButton(
                              tooltip: _speechService.isSpeaking ? 'إيقاف القراءة' : 'قراءة النص بصوت النظام',
                              onPressed: () async {
                                if (_speechService.isSpeaking) {
                                  await _speechService.stop();
                                } else {
                                  await _speechService.speak(
                                    text: '${story.title}. ${story.body}',
                                    languageCode: context.read<LanguagePreferences>().storyLanguageCode,
                                  );
                                }
                              },
                              icon: Icon(_speechService.isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up, color: RoyalColors.gold),
                            ),
                            IconButton(
                              tooltip: 'اختيار صوت النظام للقصة',
                              onPressed: _chooseStoryVoice,
                              icon: const Icon(
                                Icons.record_voice_over_outlined,
                                color: RoyalColors.cyan,
                              ),
                            ),
                            const Text('المزيد', style: TextStyle(color: RoyalColors.purple)),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _StoryEntry {
  const _StoryEntry({
    required this.title,
    required this.summary,
    required this.body,
    required this.source,
    required this.citation,
  });

  final String title;
  final String summary;
  final String body;
  final String source;
  final String citation;

  factory _StoryEntry.fromJson(Map<String, dynamic> json) => _StoryEntry(
        title: json['title'] as String? ?? 'قصة بلا عنوان',
        summary: json['summary'] as String? ?? '',
        body: json['body'] as String? ?? '',
        source: json['source'] as String? ?? 'غير محدد',
        citation: json['citation'] as String? ?? 'غير محدد',
      );
}

class _GamesPanel extends StatefulWidget {
  const _GamesPanel();

  @override
  State<_GamesPanel> createState() => _GamesPanelState();
}

class _GamesPanelState extends State<_GamesPanel> {
  final _chess = ChessGameController();
  Timer? _timer;
  int _initialMinutes = 5;
  int _whiteSeconds = 300;
  int _blackSeconds = 300;
  bool _whiteTurn = true;
  String? _selectedSquare;
  List<String> _legalTargets = const [];
  bool _computerThinking = false;
  String _gameNotice = 'ابدأ بنقل قطعة بيضاء؛ الخصم المحلي يختار حركة قانونية بتقييم مادي بسيط.';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleClock() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
      setState(() {});
      return;
    }
    if (_chess.gameOver || _whiteSeconds == 0 || _blackSeconds == 0) {
      setState(() {
        _gameNotice = _chess.gameOver
            ? _outcomeMessage()
            : 'انتهت المباراة بالوقت. ابدأ مباراة جديدة أولاً.';
      });
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_whiteTurn && _whiteSeconds > 0) _whiteSeconds--;
        if (!_whiteTurn && _blackSeconds > 0) _blackSeconds--;
        if (_whiteSeconds == 0 || _blackSeconds == 0) {
          _timer?.cancel();
          _timer = null;
          _gameNotice = _whiteSeconds == 0 ? 'انتهى وقت الأبيض.' : 'انتهى وقت الأسود.';
        }
      });
    });
    setState(() {});
  }

  String _format(int value) => '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';

  Future<void> _tapSquare(String square) async {
    if (_computerThinking || _chess.gameOver || !_chess.isWhiteTurn) return;
    if (_whiteSeconds == 0 || _blackSeconds == 0) {
      setState(() => _gameNotice = 'انتهت المباراة بالوقت. ابدأ مباراة جديدة أولاً.');
      return;
    }
    final piece = _chess.pieceAt(square);
    if (_selectedSquare == null) {
      if (piece == null || piece.color.name != 'WHITE') return;
      setState(() {
        _selectedSquare = square;
        _legalTargets = _chess.legalMovesFrom(square);
        _gameNotice = _legalTargets.isEmpty ? 'لا توجد حركة قانونية لهذه القطعة.' : 'اختر مربعاً مميزاً للحركة.';
      });
      return;
    }

    if (square == _selectedSquare) {
      setState(() {
        _selectedSquare = null;
        _legalTargets = const [];
      });
      return;
    }
    if (!_legalTargets.contains(square)) {
      if (piece != null && piece.color.name == 'WHITE') {
        setState(() {
          _selectedSquare = square;
          _legalTargets = _chess.legalMovesFrom(square);
        });
      }
      return;
    }

    final moved = _chess.movePlayer(_selectedSquare!, square);
    if (!moved) return;
    if (_chess.gameOver) {
      _timer?.cancel();
      setState(() {
        _timer = null;
        _selectedSquare = null;
        _legalTargets = const [];
        _computerThinking = false;
        _gameNotice = _outcomeMessage();
      });
      return;
    }
    setState(() {
      _selectedSquare = null;
      _legalTargets = const [];
      _whiteTurn = false;
      _computerThinking = true;
      _gameNotice = 'الخصم المحلي يفكر…';
    });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    _chess.moveComputer();
    if (!mounted) return;
    setState(() {
      _whiteTurn = _chess.isWhiteTurn;
      _computerThinking = false;
      if (_chess.gameOver) {
        _timer?.cancel();
        _timer = null;
      }
      _gameNotice = _outcomeMessage();
    });
  }

  String _outcomeMessage() {
    if (_chess.isCheckmate) return 'كش مات. انتهت المباراة.';
    if (_chess.isDraw) return 'تعادل وفق قواعد الشطرنج.';
    return 'دور الأبيض. اختر قطعة ثم مربعاً مميزاً للحركة.';
  }

  void _resetGame() {
    _timer?.cancel();
    setState(() {
      _timer = null;
      _chess.reset();
      _whiteSeconds = _initialMinutes * 60;
      _blackSeconds = _initialMinutes * 60;
      _whiteTurn = true;
      _selectedSquare = null;
      _legalTargets = const [];
      _computerThinking = false;
      _gameNotice = 'بدأت مباراة جديدة. دور الأبيض.';
    });
  }

  Widget _buildChessBoard() {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RoyalColors.gold.withValues(alpha: 0.65), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 8))],
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 64,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
          itemBuilder: (context, index) {
            final rank = 8 - (index ~/ 8);
            final file = files[index % 8];
            final square = '$file$rank';
            final piece = _chess.pieceAt(square);
            final isLight = (index ~/ 8 + index % 8).isEven;
            final isSelected = _selectedSquare == square;
            final isTarget = _legalTargets.contains(square);
            return GestureDetector(
              onTap: () => _tapSquare(square),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.amber.withValues(alpha: 0.9)
                      : isTarget
                          ? Colors.lightGreen.withValues(alpha: 0.78)
                          : isLight
                              ? const Color(0xFFB7C7D4)
                              : const Color(0xFF29455E),
                ),
                child: Center(
                  child: Text(
                    ChessGameController.pieceSymbol(piece),
                    style: TextStyle(
                      fontSize: 31,
                      height: 1,
                      color: piece?.color.name == 'WHITE' ? Colors.white : Colors.black,
                      shadows: const [Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1))],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const _SectionNotice(title: 'شطرنج وروبيك', detail: 'لوحة الشطرنج أدناه تستخدم قواعد قانونية وخصماً محلياً بسيطاً. ليست هذه بعد مشهداً ثلاثي الأبعاد؛ دمج 3D الحقيقي ينتظر نموذج توافق Flutter GPU منفصل. روبيك ثلاثي الأبعاد لم يُفعّل بعد.'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('زمن البداية: '),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _initialMinutes,
                      items: const [1, 3, 5, 10].map((minutes) => DropdownMenuItem(value: minutes, child: Text('$minutes دقائق'))).toList(),
                      onChanged: _timer == null && !_computerThinking
                          ? (minutes) {
                              if (minutes == null) return;
                              setState(() {
                                _initialMinutes = minutes;
                                _whiteSeconds = minutes * 60;
                                _blackSeconds = minutes * 60;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('الأبيض: ${_format(_whiteSeconds)}', style: const TextStyle(fontSize: 26, color: RoyalColors.text)),
                const SizedBox(height: 8),
                Text('الأسود: ${_format(_blackSeconds)}', style: const TextStyle(fontSize: 26, color: RoyalColors.text)),
                const SizedBox(height: 14),
                _buildChessBoard(),
                const SizedBox(height: 12),
                Text(_gameNotice, textAlign: TextAlign.center, style: const TextStyle(color: RoyalColors.gold, height: 1.5)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton(onPressed: _toggleClock, child: Text(_timer == null ? 'بدء الساعة' : 'إيقاف الساعة')),
                    OutlinedButton(onPressed: _resetGame, child: const Text('مباراة جديدة')),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText('PGN: ${_chess.pgn}', style: const TextStyle(color: RoyalColors.muted, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumVerificationService>(
      builder: (context, premium, _) => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _SectionNotice(title: 'PRO بتوقيع خادمي', detail: 'لا يصدر التطبيق كود تفعيل ولا يحمل مفتاحاً خاصاً. يعرض معرّف تثبيت محلياً ويرسل الباتش الموقّع إلى الخادم عند ربط API.'),
          const SizedBox(height: 16),
          const SubscriptionBoundariesCard(),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('معرّف التثبيت'),
              subtitle: SelectableText(premium.installationId),
              trailing: IconButton(
                icon: const Icon(Icons.copy, color: RoyalColors.gold),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: premium.installationId));
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ المعرّف.')));
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: RoyalColors.gold, foregroundColor: Colors.black),
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const _ProActivationPage())),
              icon: const Icon(Icons.workspace_premium),
              label: const Text('تفعيل النسخة PRO', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.record_voice_over_outlined,
                color: RoyalColors.gold,
              ),
              title: const Text('ElevenLabs — القراءة ونسخ صوت المالك'),
              subtitle: const Text(
                'الربط السحابي غير مفعّل؛ أصوات النظام المحلية هي المسار العامل الآن.',
              ),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const _ElevenLabsVoicePage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_outlined, color: RoyalColors.cyan),
              title: const Text('حزم المحتوى واللغات أوف لاين'),
              subtitle: const Text('عرض المساحة المحلية وحزم JSON المستوردة؛ نماذج ML Kit تُدار من مسار الترجمة.'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const _OfflinePackagesPage())),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.bubble_chart_outlined, color: RoyalColors.teal),
              title: const Text('الفقاعة العائمة والخصوصية'),
              subtitle: const Text('Android فقط: إذن صريح وفقاعة قابلة للسحب، بلا قراءة للتطبيقات الأخرى.'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const _BubblePrivacyPage())),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: RoyalColors.gold),
                      SizedBox(width: 10),
                      Text('نبذة عن التطبيق', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text('ميرور سكربيون: حيث تُصنع البدايات', style: TextStyle(color: RoyalColors.cyan, fontWeight: FontWeight.w700, fontSize: 17)),
                  SizedBox(height: 10),
                  Text('الوقت هو العملة الأغلى التي مُنحت للإنسان. هنا، نحن لا نقيس أعمارنا بالسنوات، بل بكل ثانية نصنع فيها إنجازاً حقيقياً.\n\nهنا ستكتشف أن كل انكسار مررت به لم يكن إلا تمهيداً لانطلاقة أعظم؛ فالماضي ليس للمحو، بل للتعلّم، والمستقبل هو ما يستحق انتباهك الآن.\n\nتذكّر دائماً: قصتك لا تزال تُكتب، والنهاية لم يحن وقتها بعد.', style: TextStyle(color: RoyalColors.muted, height: 1.65, fontSize: 15)),
                  SizedBox(height: 14),
                  Divider(),
                  SizedBox(height: 8),
                  Text('المطور', style: TextStyle(color: RoyalColors.gold, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Tamer Eldosoky', textDirection: TextDirection.ltr, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElevenLabsVoicePage extends StatelessWidget {
  const _ElevenLabsVoicePage();

  void _showConsentSummary(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0D1623),
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ملخص الموافقة قبل نسخ الصوت',
                    style: TextStyle(
                      color: RoyalColors.gold,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'لن تكون ميزة النسخ متاحة إلا لمن عمره 18 عاماً أو أكثر، '
                    'ولصوت المالك أو صاحب تفويض صريح فقط. لا يقرأ التطبيق '
                    'رسائلك أو مكالماتك، ولا يرفع تسجيلاً تلقائياً. عند التفعيل '
                    'سيظهر عقد موافقة مستقل وخيار حذف واضح قبل إرسال عينة.',
                    style: TextStyle(height: 1.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'المرجع داخل المشروع: ${ElevenLabsVoiceService.consentDocumentPath}',
                    style: const TextStyle(
                      color: RoyalColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('فهمت'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ElevenLabsVoiceService>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إعداد ElevenLabs')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const _SectionNotice(
              title: 'حالة صوت صادقة',
              detail:
                  'تعمل القراءة الحالية بصوت النظام المثبت على جهازك. لا يعمل ElevenLabs في هذه النسخة بعد، ولا يرسل التطبيق نصاً أو عينة أو مفتاحاً إلى أي مزود.',
            ),
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.phonelink_lock_outlined,
                  color: RoyalColors.cyan,
                ),
                title: const Text('حالة الخادم الوسيط'),
                subtitle: Text(service.statusMessage),
                trailing: const Icon(
                  Icons.cloud_off_outlined,
                  color: RoyalColors.muted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'قراءة سحابية اختيارية',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ستُستخدم لاحقاً لقراءة نص تختاره فقط. لا تعد بديلاً عن أصوات النظام ولا تعمل قبل اعتماد الخطة والخادم وحد الاستخدام.',
                      style: TextStyle(
                        color: RoyalColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: null,
                      icon: Icon(Icons.cloud_off_outlined),
                      label: Text('الخادم غير مفعّل'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'نسخ صوت المالك',
                      style: TextStyle(
                        color: RoyalColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'مغلق الآن. عند إطلاقه سيطلب موافقة منفصلة، تأكيد العمر وملكية الصوت، ثم يسمح بعينة يختارها المستخدم يدوياً. لا يدعم نسخ أصوات الغير أو تشغيل التسجيل في الخلفية.',
                      style: TextStyle(
                        color: RoyalColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _showConsentSummary(context),
                      icon: const Icon(Icons.privacy_tip_outlined),
                      label: const Text('اطلع على ملخص الموافقة والحذف'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: null,
                      icon: Icon(Icons.lock_outline),
                      label: Text('لا يمكن رفع عينة الآن'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflinePackagesPage extends StatefulWidget {
  const _OfflinePackagesPage();

  @override
  State<_OfflinePackagesPage> createState() => _OfflinePackagesPageState();
}

class _OfflinePackagesPageState extends State<_OfflinePackagesPage> {
  final _storage = const OfflineContentStorage();
  final _catalogService = GitHubContentCatalogService();
  late Future<List<OfflinePackageRecord>> _packages;
  late Future<ContentCatalogLoadResult> _catalog;
  bool _isDownloading = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _packages = _storage.listPackages();
    _catalog = _catalogService.fetchCatalog();
  }

  @override
  void dispose() {
    _catalogService.dispose();
    super.dispose();
  }

  void _refreshCatalog() {
    setState(() => _catalog = _catalogService.fetchCatalog());
  }

  Future<void> _downloadPackage(
    ContentCatalog catalog,
    ContentCatalogPackage package,
  ) async {
    setState(() {
      _isDownloading = true;
      _notice = 'جارٍ تنزيل «${package.title}» والتحقق من سلامتها…';
    });
    final result = await _catalogService.downloadPackage(
      catalog: catalog,
      package: package,
      storage: _storage,
    );
    if (!mounted) return;
    setState(() {
      _isDownloading = false;
      _notice = result.message;
      if (result.success) _packages = _storage.listPackages();
    });
  }

  Future<void> _deletePackage(OfflinePackageRecord package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الحزمة؟'),
        content: Text('سيُحذف «${package.title}» من مساحة التطبيق فقط.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await _storage.deletePackage(package.id);
    if (!mounted) return;
    setState(() {
      _packages = _storage.listPackages();
      _notice = deleted
          ? 'تم حذف «${package.title}» من مساحة التطبيق.'
          : 'لم تعد الحزمة موجودة في مساحة التطبيق.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الحزم المحلية')),
        body: FutureBuilder<List<OfflinePackageRecord>>(
          future: _packages,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final packages = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const _SectionNotice(
                  title: 'مساحة العمل أوفلاين',
                  detail: 'تعرض هذه المساحة حزم JSON التي اختارها المستخدم فقط. تتحقق الحزم المتاحة من SHA-256 قبل الحفظ؛ المصادر غير الموثقة لا يظهر لها تنزيل.',
                ),
                const SizedBox(height: 16),
                if (packages.isEmpty)
                  const Card(child: ListTile(title: Text('لا توجد حزم مستوردة بعد'), subtitle: Text('يمكن استيراد حزمة JSON من كارت القصص.'))),
                ...packages.map(
                  (item) => Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.inventory_2_outlined,
                        color: RoyalColors.cyan,
                      ),
                      title: Text(item.title),
                      subtitle: Text(
                        '${item.id}${item.version == null ? '' : ' • v${item.version}'}',
                      ),
                      trailing: IconButton(
                        tooltip: 'حذف الحزمة من الجهاز',
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deletePackage(item),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FutureBuilder<ContentCatalogLoadResult>(
                  future: _catalog,
                  builder: (context, catalogSnapshot) {
                    if (!catalogSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final catalogResult = catalogSnapshot.data!;
                    if (!catalogResult.isSuccess) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.cloud_off_outlined),
                          title: const Text('تعذر تحميل فهرس المصادر'),
                          subtitle: Text(catalogResult.message),
                          trailing: IconButton(
                            tooltip: 'إعادة المحاولة',
                            icon: const Icon(Icons.refresh),
                            onPressed: _refreshCatalog,
                          ),
                        ),
                      );
                    }
                    final catalog = catalogResult.catalog!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'حزم متاحة من GitHub',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            IconButton(
                              tooltip: 'تحديث الفهرس',
                              icon: const Icon(Icons.refresh, color: RoyalColors.gold),
                              onPressed: _isDownloading ? null : _refreshCatalog,
                            ),
                          ],
                        ),
                        ...catalog.packages.map(
                          (package) => Card(
                            child: ListTile(
                              leading: Icon(
                                package.canDownload
                                    ? Icons.download_for_offline_outlined
                                    : Icons.verified_outlined,
                                color: package.canDownload
                                    ? RoyalColors.gold
                                    : RoyalColors.muted,
                              ),
                              title: Text(package.title),
                              subtitle: Text(
                                package.canDownload
                                    ? '${package.scope} • ${package.sourceName ?? 'مصدر غير محدد'}'
                                    : package.reason ?? 'قيد المراجعة قبل الإتاحة.',
                              ),
                              trailing: package.canDownload
                                  ? FilledButton(
                                      onPressed: _isDownloading
                                          ? null
                                          : () => _downloadPackage(catalog, package),
                                      child: const Text('تنزيل'),
                                    )
                                  : const Text(
                                      'قيد المراجعة',
                                      style: TextStyle(color: RoyalColors.muted),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (_notice != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _notice!,
                      style: const TextStyle(color: RoyalColors.gold, height: 1.5),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BubblePrivacyPage extends StatefulWidget {
  const _BubblePrivacyPage();

  @override
  State<_BubblePrivacyPage> createState() => _BubblePrivacyPageState();
}

class _BubblePrivacyPageState extends State<_BubblePrivacyPage> {
  final _overlayService = AndroidOverlayService();
  String? _notice;
  bool _isWorking = false;

  Future<void> _startBubble() async {
    setState(() => _isWorking = true);
    final result = await _overlayService.showBubble();
    if (!mounted) return;
    setState(() {
      _isWorking = false;
      _notice = result.message;
    });
  }

  Future<void> _stopBubble() async {
    setState(() => _isWorking = true);
    final result = await _overlayService.closeBubble();
    if (!mounted) return;
    setState(() {
      _isWorking = false;
      _notice = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الفقاعة العائمة والخصوصية')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const _SectionNotice(
              title: 'حدود الفقاعة',
              detail: 'هذه هي الدفعة الأولى: فقاعة Android قابلة للسحب تظهر فقط بعد إذنك وتحت إشعار foreground. لا تستقبل بعد نص Share أو Process Text؛ لا تقرأ التطبيقات الأخرى مطلقاً.',
            ),
            const SizedBox(height: 12),
            const Card(child: ListTile(leading: Icon(Icons.block_outlined, color: Colors.redAccent), title: Text('غير مسموح'), subtitle: Text('لا خدمة Accessibility، ولا Notification Listener، ولا قراءة تلقائية لرسائل WhatsApp أو البريد أو Messenger.'))),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: RoyalColors.gold),
                title: Text(_overlayService.isSupported ? 'Android Overlay متاح للاختبار' : 'هذه المنصة لا تدعم Overlay'),
                subtitle: const Text('تفعيل الفقاعة يفتح صفحة الإذن الرسمية من Android عند الحاجة.'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isWorking || !_overlayService.isSupported ? null : _startBubble,
              icon: _isWorking
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.bubble_chart_outlined),
              label: const Text('تفعيل الفقاعة فوق التطبيقات'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isWorking || !_overlayService.isSupported ? null : _stopBubble,
              icon: const Icon(Icons.close),
              label: const Text('إيقاف الفقاعة'),
            ),
            if (_notice != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(_notice!, style: const TextStyle(color: RoyalColors.gold, height: 1.5)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProActivationPage extends StatefulWidget {
  const _ProActivationPage();

  @override
  State<_ProActivationPage> createState() => _ProActivationPageState();
}

class _ProActivationPageState extends State<_ProActivationPage> {
  final _patchController = TextEditingController();
  String? _notice;

  @override
  void dispose() {
    _patchController.dispose();
    super.dispose();
  }

  Future<void> _pastePatch() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) setState(() => _patchController.text = data!.text!);
  }

  void _activate() {
    setState(() {
      _notice = _patchController.text.trim().isEmpty
          ? 'ألصق باتش التفعيل الموقّع أولاً.'
          : 'لم يُربط مسار التحقق الخادمي بعد؛ لم يتم تفعيل PRO محلياً.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تفعيل النسخة PRO')),
        body: Consumer<PremiumVerificationService>(
          builder: (context, premium, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _SectionNotice(
                title: 'المزايا الاحترافية',
                detail: 'الفقاعة العائمة، تنزيلات أوفلاين، وثائق بلا حد، صوت المستخدم، ومشاهد الفيديو. تتطلب جميعها تحققاً موقعاً من الخادم واتصالاً بالإنترنت ووقتاً موثوقاً.',
              ),
              const SizedBox(height: 18),
              const Text('معرّف التثبيت', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 4, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: RoyalColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        premium.installationId,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    IconButton(
                      tooltip: 'نسخ المعرّف',
                      icon: const Icon(Icons.copy, color: RoyalColors.gold),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: premium.installationId));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ معرّف التثبيت.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('باتش التفعيل الموقّع', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              TextField(
                controller: _patchController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'MS4.payload.signature',
                  suffixIcon: IconButton(tooltip: 'لصق', icon: const Icon(Icons.content_paste, color: RoyalColors.gold), onPressed: _pastePatch),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                  onPressed: _activate,
                  icon: const Icon(Icons.verified_user),
                  label: const Text('تفعيل'),
                ),
              ),
              if (_notice != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_notice!, style: const TextStyle(color: RoyalColors.gold, height: 1.5))),
              const SizedBox(height: 24),
              const Text(
                'التواصل لتفعيل الاشتراك',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              const SizedBox(height: 12),
              _ContactMethodCard(
                icon: Icons.chat_bubble,
                iconColor: const Color(0xFF25D366),
                label: 'WhatsApp',
                value: '01017341250',
              ),
              const SizedBox(height: 10),
              _ContactMethodCard(
                icon: Icons.chat_bubble,
                iconColor: const Color(0xFF25D366),
                label: 'WhatsApp',
                value: '01031680816',
              ),
              const SizedBox(height: 10),
              _ContactMethodCard(
                icon: Icons.chat_bubble,
                iconColor: const Color(0xFF25D366),
                label: 'WhatsApp',
                value: '01558203456',
              ),
              const SizedBox(height: 10),
              _ContactMethodCard(
                icon: Icons.alternate_email,
                iconColor: const Color(0xFFEA4335),
                label: 'البريد الإلكتروني',
                value: 'dosoky.server@gmail.com',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactMethodCard extends StatelessWidget {
  const _ContactMethodCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $value. اضغط للنسخ',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم نسخ $value')),
            );
          }
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2838),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: iconColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: RoyalColors.muted, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.copy_outlined, color: RoyalColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionNotice extends StatelessWidget {
  const _SectionNotice({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RoyalColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoyalColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(detail, style: const TextStyle(color: RoyalColors.muted, height: 1.55)),
        ],
      ),
    );
  }
}
