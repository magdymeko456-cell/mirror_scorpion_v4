import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/royal_dark_theme.dart';
import '../core/mlkit/on_device_ocr_service.dart';
import '../core/mlkit/on_device_translation_service.dart';
import '../core/pro/premium_verification_service.dart';

enum FeatureKind { translation, dialogue, documents, stories, games, settings }

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
  String _selectedLanguage = 'ar';
  String? _notice;
  bool _clearOnNextInput = false;
  bool _isTranslating = false;
  Timer? _translationDebounce;
  static const _languages = <String, String>{
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

  @override
  void initState() {
    super.initState();
    _loadLastLanguage();
  }

  Future<void> _loadLastLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString('mirror_scorpion_translation_target');
    if (saved != null && _languages.containsKey(saved) && mounted) {
      setState(() => _selectedLanguage = saved);
    }
  }

  Future<void> _selectLanguage(String code) async {
    setState(() => _selectedLanguage = code);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('mirror_scorpion_translation_target', code);
    _queueTranslation(_input.text);
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

  void _queueTranslation(String value) {
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
      _translateLocally(value);
    });
  }

  Future<void> _translateLocally(String value) async {
    if (!mounted || value.trim() != _input.text.trim()) return;
    setState(() {
      _isTranslating = true;
      _notice = 'جارٍ تحديد لغة النص وتجهيز نموذج الترجمة المحلي…';
    });
    final result = await _translationService.translate(
      text: value,
      targetLanguageCode: _selectedLanguage,
    );
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
                items: _languages.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
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
            _EditorAction(icon: Icons.mic, tooltip: 'التقاط الكلام', onPressed: () => _beginNewInput('التقاط الكلام')),
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
            _EditorAction(icon: Icons.volume_up, tooltip: 'نطق الترجمة', onPressed: () => _beginNewInput('نطق الترجمة')),
            _EditorAction(icon: Icons.share, tooltip: 'مشاركة ملف صوت مترجم', onPressed: () => _beginNewInput('مشاركة الترجمة')),
            _EditorAction(icon: Icons.attach_file, tooltip: 'رفع ملف صوتي', onPressed: () => _beginNewInput('رفع الملف الصوتي')),
            _EditorAction(icon: Icons.copy, tooltip: 'نسخ الترجمة', onPressed: () async {
              if (_output.text.isNotEmpty) await Clipboard.setData(ClipboardData(text: _output.text));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد نص مترجم لنسخه بعد.')));
            }),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionNotice(title: 'ترجمة محلية صادقة', detail: 'تحدد ML Kit لغة النص وتنزّل نموذجَي المصدر والهدف عند الحاجة، ثم تترجم على الجهاز. القائمة المرئية واسعة، لكن تظهر حالة واضحة إذا كانت لغة مختارة خارج اللغات التي يدعمها ML Kit محلياً.'),
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
  final _left = TextEditingController();
  final _right = TextEditingController();

  @override
  void dispose() {
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const _SectionNotice(title: 'حوار ثنائي اللغة', detail: 'يُحافظ هذا القسم على طرفي الحوار ولا يُترجم النص يدوياً داخل الجهاز. التسجيل والترجمة الفعلية يرتبطان بمسار الصوت الخادمي.'),
        const SizedBox(height: 16),
        TextField(controller: _left, minLines: 5, maxLines: 8, decoration: const InputDecoration(labelText: 'طرف الحوار الأول', alignLabelWithHint: true)),
        const SizedBox(height: 12),
        const Icon(Icons.swap_vert, color: RoyalColors.teal),
        const SizedBox(height: 12),
        TextField(controller: _right, minLines: 5, maxLines: 8, decoration: const InputDecoration(labelText: 'طرف الحوار الثاني', alignLabelWithHint: true)),
      ],
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
  bool _isScanning = false;
  String? _selectedFileName;
  String? _extractedText;
  String? _notice;

  Future<void> _scanImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 100);
    if (image == null) {
      if (mounted) setState(() => _notice = 'لم يتم اختيار صورة.');
      return;
    }
    final stopwatch = Stopwatch()..start();
    setState(() {
      _isScanning = true;
      _selectedFileName = image.name;
      _extractedText = null;
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
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const _SectionNotice(title: 'OCR بلا نتيجة مصطنعة', detail: 'تفحص العدسة الصورة المختارة محلياً وتعرض النص المستخرج بعد ثلاث ثوانٍ على الأقل. الإصدار المحلي الحالي يقرأ النص اللاتيني فقط؛ العربية وPDF يتطلبان محركاً مناسباً أو خدمة خادم لاحقاً.'),
        const SizedBox(height: 20),
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
        if (_isScanning)
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
              child: SelectableText(_extractedText!, style: const TextStyle(height: 1.6)),
            ),
          ),
      ],
    );
  }
}

class _StoriesPanel extends StatelessWidget {
  const _StoriesPanel();

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
        const _SectionNotice(title: 'قصص وإلهام آمن', detail: 'القراءة الصوتية وسيناريو الفيديو يعتمدان على خدمات منفصلة. يبقى إنتاج MP4 خارج نطاق التطبيق حتى يربط مزود فيديو حقيقي.'),
        const SizedBox(height: 12),
        ...stories.map((story) => Card(child: ListTile(title: Text(story.$1), subtitle: Text(story.$2), trailing: const Text('المزيد', style: TextStyle(color: RoyalColors.purple))))),
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
