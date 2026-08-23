import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app/royal_dark_theme.dart';
import '../core/localization/language_preferences.dart';
import '../core/mlkit/on_device_ocr_service.dart';
import '../core/mlkit/on_device_translation_service.dart';
import '../core/pro/premium_verification_service.dart';
import '../core/speech/device_speech_recognition_service.dart';
import '../core/speech/system_tts_service.dart';

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
  bool _clearOnNextInput = false;
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
      final saved = context.read<LanguagePreferences>().translationTargetLanguage;
      if (TranslationLanguageCatalog.labels.containsKey(saved)) _selectedLanguage = saved;
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
    final sourceLanguage = context.read<LanguagePreferences>().translationSourceLanguage;
    await _speechService.stop();
    await _recognitionService.start(
      languageCode: sourceLanguage,
      onText: (recognizedText) {
        if (!mounted) return;
        if (_clearOnNextInput) {
          _input.clear();
          _output.clear();
          _clearOnNextInput = false;
        }
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

  void _audioUploadUnavailable() {
    setState(() {
      _notice = 'اختيار الملف موجود في محرر المصدر، لكن تفريغ الملفات وترجمتها لم يُربطا بعد بخدمة صوت حية؛ لن يُنتج التطبيق ترجمة وهمية.';
    });
  }

  void _beginNewInput(String action) {
    if (_clearOnNextInput) {
      _input.clear();
      _output.clear();
      _notice = null;
      _clearOnNextInput = false;
    }
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
    if (result.sourceLanguage != null) {
      await context
          .read<LanguagePreferences>()
          .setTranslationSourceLanguage(result.sourceLanguage!);
    }
    if (!mounted || value.trim() != _input.text.trim()) return;
    setState(() {
      _isTranslating = false;
      if (result.isSuccess) _output.text = result.text ?? '';
      if (!result.isSuccess) _output.clear();
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        const SizedBox(height: 4),
        Center(
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 1.5),
                  image: const DecorationImage(image: AssetImage('assets/images/scorpion_bg.jpeg'), fit: BoxFit.cover),
                ),
              ),
              Container(
                width: 120,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.transparent, Colors.cyanAccent.withValues(alpha: 0.4), Colors.transparent]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2838),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4), width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLanguage,
                isExpanded: true,
                dropdownColor: const Color(0xFF1B2838),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.cyanAccent),
                items: TranslationLanguageCatalog.labels.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
                onChanged: (code) {
                  if (code != null) _selectLanguage(code);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        _TranslationEditor(
          controller: _input,
          hint: 'ابدأ بالكتابة أو اضغط المايك للتحدث...',
          readOnly: false,
          actionsOnRight: false,
          onTap: () {
            if (_clearOnNextInput) _beginNewInput('جلسة ترجمة جديدة');
          },
          onChanged: _queueTranslation,
          actions: [
            _EditorAction(
              icon: _recognitionService.isListening ? Icons.stop_circle_outlined : Icons.mic,
              tooltip: _recognitionService.isListening ? 'إيقاف التقاط الكلام' : 'التقاط الكلام من ميكروفون الجهاز',
              onPressed: _toggleMicrophone,
            ),
            _EditorAction(
              icon: Icons.attach_file,
              tooltip: 'اختيار ملف صوتي لترجمته',
              onPressed: _audioUploadUnavailable,
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
        const SizedBox(height: 14),
        _TranslationEditor(
          controller: _output,
          hint: 'ستظهر ترجمة ML Kit المحلية هنا بعد تنزيل النماذج.',
          readOnly: true,
          actionsOnRight: true,
          actions: [
            _EditorAction(icon: _speechService.isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up, tooltip: _speechService.isSpeaking ? 'إيقاف النطق' : 'نطق الترجمة بصوت النظام', onPressed: _speakTranslation),
            _EditorAction(icon: Icons.share, tooltip: 'مشاركة ملف صوت مترجم', onPressed: () => _beginNewInput('مشاركة الترجمة')),
            _EditorAction(icon: Icons.copy, tooltip: 'نسخ الترجمة', onPressed: () async {
              if (_output.text.isNotEmpty) await Clipboard.setData(ClipboardData(text: _output.text));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد نص مترجم لنسخه بعد.')));
            }),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionNotice(title: 'ترجمة محلية صادقة', detail: 'تبدأ تفضيلات الترجمة من لغة الجهاز ثم تحفظ آخر لغة مصدر وهدف. يطلب زر الميكروفون إذنًا صريحًا ويستخدم تعرف الكلام المتاح في الجهاز للجمل القصيرة، ثم تمرر النتيجة إلى ML Kit للترجمة المحلية. دبوس محرر المصدر مخصص لملفات الصوت، لكنه ينتظر خدمة تفريغ فعلية ولا ينتج ترجمة مصطنعة. صوت القراءة هو صوت النظام المتاح، وليس أحد الأصوات المميزة أو صوت المستخدم بعد.'),
      ],
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
      height: 180,
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
            maxLines: 5,
            style: const TextStyle(color: Colors.white, fontSize: 17),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 15),
              border: InputBorder.none,
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
  String _rightSourceLanguage = 'ar';
  String _leftTargetLanguage = 'en';
  String? _notice;
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
    _rightSourceLanguage = preferences.translationSourceLanguage;
    _leftTargetLanguage = preferences.translationTargetLanguage;
    _loadedLanguagePreferences = true;
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _selectRightSourceLanguage(String code) async {
    setState(() => _rightSourceLanguage = code);
    await context.read<LanguagePreferences>().setTranslationSourceLanguage(code);
    _queueTranslation(_source.text, sourceLanguageCode: code);
  }

  Future<void> _selectLeftTargetLanguage(String code) async {
    setState(() => _leftTargetLanguage = code);
    await context.read<LanguagePreferences>().setTranslationTargetLanguage(code);
    _queueTranslation(_source.text, sourceLanguageCode: _rightSourceLanguage);
  }

  Future<void> _swapLanguages() async {
    await context.read<LanguagePreferences>().swapTranslationLanguages();
    if (!mounted) return;
    final preferences = context.read<LanguagePreferences>();
    setState(() {
      _rightSourceLanguage = preferences.translationSourceLanguage;
      _leftTargetLanguage = preferences.translationTargetLanguage;
      _source.clear();
      _translated.clear();
      _notice = 'تم تبديل اللغتين. يبقى المحرر العلوي دائماً تابعاً لزر اللغة في اليمين.';
    });
  }

  Future<void> _toggleMicrophone() async {
    if (_recognitionService.isListening) {
      await _recognitionService.stop();
      if (mounted && _recognitionService.message != null) {
        setState(() => _notice = _recognitionService.message);
      }
      return;
    }
    await _speechService.stop();
    final sourceLanguage = _rightSourceLanguage;
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
      sourceLanguageCode: sourceLanguageCode ?? _rightSourceLanguage,
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

  void _audioFileUnavailable() {
    setState(() {
      _notice = 'دبوس محرر المصدر جاهز لاختيار ملف صوت، لكن تفريغ الملف وترجمته يحتاجان خدمة صوت حية؛ لا توجد نتيجة بديلة مصطنعة.';
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
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const _SectionNotice(title: 'حوار ثنائي اللغة محلي', detail: 'المحرر العلوي هو المصدر ويتبع زر اللغة في اليمين دائماً، والمحرر السفلي هو الناتج ويتبع زر اللغة في اليسار. يلتقط الميكروفون كلام الطرف العلوي فقط بإذن صريح ثم يترجمه ML Kit محلياً.'),
        const SizedBox(height: 16),
        _DialogueEditor(
          controller: _source,
          label: 'المحرر العلوي — المصدر (زر اليمين)',
          hint: 'اكتب أو اضغط الميكروفون ليسمع لغة المصدر…',
          actions: [
            _EditorAction(
              icon: Icons.attach_file,
              tooltip: 'اختيار ملف صوت لمصدر الحوار',
              onPressed: _audioFileUnavailable,
            ),
          ],
          onChanged: (value) => _queueTranslation(
            value,
            sourceLanguageCode: _rightSourceLanguage,
          ),
        ),
        const SizedBox(height: 12),
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
                  label: 'الهدف — يسار',
                  onChanged: _selectLeftTargetLanguage,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: RoyalColors.gold, size: 28),
                tooltip: 'تبديل لغة المصدر والهدف',
                onPressed: _swapLanguages,
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
                child: _DialogueLanguageMenu(
                  value: _rightSourceLanguage,
                  label: 'المصدر — يمين',
                  onChanged: _selectRightSourceLanguage,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DialogueEditor(
          controller: _translated,
          label: 'المحرر السفلي — ترجمة الهدف (زر اليسار)',
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
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final List<_EditorAction> actions;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
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
              minLines: 5,
              maxLines: null,
              style: const TextStyle(color: Colors.white, fontSize: 17),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white30),
                border: InputBorder.none,
              ),
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
  final _translationService = const OnDeviceTranslationService();
  bool _isScanning = false;
  bool _isTranslating = false;
  String? _selectedFileName;
  String? _extractedText;
  String? _translatedText;
  String? _notice;
  String _targetLanguage = 'en';
  bool _loadedLanguagePreference = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedLanguagePreference) return;
    final saved = context.read<LanguagePreferences>().translationTargetLanguage;
    if (TranslationLanguageCatalog.labels.containsKey(saved)) {
      _targetLanguage = saved;
    }
    _loadedLanguagePreference = true;
  }

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
    final targetLanguage = _targetLanguage;
    setState(() {
      _isTranslating = true;
      _translatedText = null;
      _notice = 'جارٍ ترجمة النص المستخرج إلى ${TranslationLanguageCatalog.labels[targetLanguage] ?? targetLanguage}…';
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

  Future<void> _selectTargetLanguage(String code) async {
    setState(() => _targetLanguage = code);
    await context.read<LanguagePreferences>().setTranslationTargetLanguage(code);
    final extractedText = _extractedText;
    if (extractedText != null && extractedText.trim().isNotEmpty) {
      await _translateExtractedText(extractedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const _SectionNotice(title: 'عدسة OCR وترجمة محلية', detail: 'تفحص العدسة الصورة المختارة محلياً ثم تمرر النص المستخرج إلى ML Kit للترجمة نحو اللغة المختارة. الإصدار المحلي الحالي يقرأ النص اللاتيني فقط؛ العربية وPDF يتطلبان محركاً مناسباً أو خدمة خادم لاحقاً.'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2838),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _targetLanguage,
              isExpanded: true,
              dropdownColor: const Color(0xFF1B2838),
              icon: const Icon(Icons.translate, color: Colors.cyanAccent),
              items: TranslationLanguageCatalog.labels.entries
                  .map((entry) => DropdownMenuItem(value: entry.key, child: Text('ترجمة إلى: ${entry.value}')))
                  .toList(),
              onChanged: _isScanning || _isTranslating
                  ? null
                  : (code) {
                      if (code != null) _selectTargetLanguage(code);
                    },
            ),
          ),
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
            subtitle: const Text('OCR محلي للصورة؛ PDF مؤجل لمسار مستقل'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _isScanning ? null : () => _scanImage(ImageSource.gallery),
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
                  Text('الترجمة إلى: ${TranslationLanguageCatalog.labels[_targetLanguage] ?? _targetLanguage}', style: const TextStyle(color: RoyalColors.gold)),
                  const SizedBox(height: 8),
                  SelectableText(_translatedText!, style: const TextStyle(height: 1.6)),
                ],
              ),
            ),
          ),
      ],
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

  @override
  void initState() {
    super.initState();
    _speechService.addListener(_onSpeechChanged);
    _speechService.initialize();
  }

  void _onSpeechChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _speechService.removeListener(_onSpeechChanged);
    _speechService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const stories = [
      ('رسالة احترام', 'القصص التي يكتبها المستخدم تُراجع قبل العرض لمنع الكراهية والتنمر والألفاظ البذيئة.'),
      ('قصص الأنبياء', 'سيُنقل الفهرس المحلي والمصادر القابلة للتنزيل إلى JSON موثق داخل التطبيق.'),
      ('أسباب النزول', 'يعرض القسم المصدر وحالة التنزيل بدلاً من ادعاء توفر نص لم يُحفظ بعد.'),
    ];
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const _SectionNotice(title: 'قصص وإلهام آمن', detail: 'تبدأ لغة القراءة من لغة الجهاز عند توفر بيانات مترجمة. يمكن تجربة صوت النظام على النصوص الظاهرة؛ أما الأصوات المميزة وسيناريو الفيديو فيتطلبان خدمات منفصلة.'),
        const SizedBox(height: 12),
        ...stories.map(
          (story) => Card(
            child: ListTile(
              title: Text(story.$1),
              subtitle: Text(story.$2),
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
                          text: '${story.$1}. ${story.$2}',
                          languageCode: context.read<LanguagePreferences>().storyLanguageCode,
                        );
                      }
                    },
                    icon: Icon(_speechService.isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up, color: RoyalColors.gold),
                  ),
                  const Text('المزيد', style: TextStyle(color: RoyalColors.purple)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GamesPanel extends StatefulWidget {
  const _GamesPanel();

  @override
  State<_GamesPanel> createState() => _GamesPanelState();
}

class _GamesPanelState extends State<_GamesPanel> {
  Timer? _timer;
  int _whiteSeconds = 300;
  int _blackSeconds = 300;
  bool _whiteTurn = true;

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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_whiteTurn && _whiteSeconds > 0) _whiteSeconds--;
        if (!_whiteTurn && _blackSeconds > 0) _blackSeconds--;
      });
    });
    setState(() {});
  }

  String _format(int value) => '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const _SectionNotice(title: 'شطرنج وروبيك', detail: 'ساعة الشطرنج تعمل محلياً. محرك الشطرنج والمشهد ثلاثي الأبعاد الكامل يدخلان بعد اختبار Flame/Flame 3D على جهاز Android.'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text('الأبيض: ${_format(_whiteSeconds)}', style: const TextStyle(fontSize: 26, color: RoyalColors.text)),
                const SizedBox(height: 8),
                Text('الأسود: ${_format(_blackSeconds)}', style: const TextStyle(fontSize: 26, color: RoyalColors.text)),
                const SizedBox(height: 14),
                FilledButton(onPressed: _toggleClock, child: Text(_timer == null ? 'بدء الساعة' : 'إيقاف الساعة')),
                TextButton(onPressed: () => setState(() => _whiteTurn = !_whiteTurn), child: const Text('تبديل الدور')),
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
          const Card(child: ListTile(leading: Icon(Icons.download_outlined, color: RoyalColors.cyan), title: Text('حزم لغات أوف لاين'), subtitle: Text('تُضاف بعد اختيار محرك الترجمة وملفات النماذج المعتمدة.'))),
          const SizedBox(height: 12),
          const Card(child: ListTile(leading: Icon(Icons.bubble_chart_outlined, color: RoyalColors.teal), title: Text('الفقاعة العائمة'), subtitle: Text('تحتاج خدمة Android Foreground وإذن الظهور فوق التطبيقات.'))),
        ],
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
              TextField(
                controller: TextEditingController(text: premium.installationId),
                readOnly: true,
                maxLines: 2,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    tooltip: 'نسخ المعرّف',
                    icon: const Icon(Icons.copy, color: RoyalColors.gold),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: premium.installationId));
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ معرّف التثبيت.')));
                    },
                  ),
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
              const Text('التواصل لتفعيل الاشتراك', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('WhatsApp: 01017341250\nWhatsApp: 01031680816\nWhatsApp: 01558203456\nالبريد: dosoky.server@gmail.com', style: TextStyle(color: RoyalColors.muted, height: 1.6)),
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
