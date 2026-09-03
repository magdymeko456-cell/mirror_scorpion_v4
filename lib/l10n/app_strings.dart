import 'dart:ui';

/// ترجمة بلا codegen — تعمل على Termux وكل مكان.
/// الـ locale يُضبط مرة في main() فلا نحتاج context في أي موقع استدعاء.
class AppStrings {
  static Locale _locale = const Locale('ar');
  static void setLocale(Locale l) => _locale = l;

  static String _pick(String ar, String en) =>
      _locale.languageCode == 'en' ? en : ar;

  // ——— المحرر العلوي (الحوار) ———
  static String editorTopLabelDevice() =>
      _pick('المحرر العلوي — المتحدث بلغة الجهاز', 'Top editor — speaking device language');
  static String editorTopHintDevice() =>
      _pick('اكتب أو تحدث بلغة جهازك…', 'Type or speak in your device language…');
  static String editorTopLabelCounterpart() =>
      _pick('المحرر العلوي — المتحدث باللغة المقابلة', 'Top editor — speaking counterpart language');
  static String editorTopHintCounterpart() =>
      _pick('اكتب أو تحدث باللغة المقابلة…', 'Type or speak in the counterpart language…');
  static String nowMicSource() => _pick('مصدر المايك الآن', 'Mic source now');
  static String nowTranslation() => _pick('لغة الترجمة الآن', 'Translation language now');
}
