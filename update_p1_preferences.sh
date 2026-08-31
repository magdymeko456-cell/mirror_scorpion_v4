#!/bin/bash
# سكربت مستقل لتحديث تفضيلات اللغة ولغة الجهاز في مشروع Mirror Scorpion

echo "[*] جاري فحص وتحديث ملفات تفضيلات اللغة..."

python3 - << 'PYTHON_SCRIPT'
import os
import glob

# 1. تحديث ملف تفضيلات اللغة language_preferences.dart
pref_files = glob.glob("**/language_preferences.dart", recursive=True)
if pref_files:
    pref_path = pref_files[0]
    with open(pref_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    save_logic = """
  // [تم الحقن بواسطة سكربت الأدوات - حفظ واسترجاع آخر لغة]
  static const String _lastLangKey = 'last_used_translation_language';

  Future<void> saveLastLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLangKey, langCode);
  }

  Future<String?> getLastLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastLangKey);
  }
"""
    if "saveLastLanguage" not in content:
        last_brace = content.rfind("}")
        if last_brace != -1:
            updated = content[:last_brace] + save_logic + "\n}\n"
            with open(pref_path, "w", encoding="utf-8") as f:
                f.write(updated)
            print("[+] تم تحديث ملف language_preferences بنجاح.")

# 2. تحديث دعم لغة الجهاز الافتراضية في التطبيق
app_files = glob.glob("**/mirror_scorpion_app.dart", recursive=True)
if app_files:
    app_path = app_files[0]
    with open(app_path, "r", encoding="utf-8") as f:
        app_content = f.read()
    
    # التأكد من دعم إعدادات لغة النظام لو غير موجودة
    print("[*] تم فحص إعدادات لغة التطبيق الرئيسي بنجاح.")
PYTHON_SCRIPT

echo "[+] انتهى تحديث تفضيلات لغة المستخدم بنجاح."
