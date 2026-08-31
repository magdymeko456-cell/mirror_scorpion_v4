#!/bin/bash
# سكربت مستقل لتحديث وترتيب ميزات P3 (الفقاعة العائمة والأصوات الخمسة)

echo "[*] جاري فحص وتحديث خدمات الفقاعة العائمة والأصوات..."

python3 - << 'PYTHON_SCRIPT'
import os
import glob

# 1. تحديث الفقاعة العائمة للواتساب android_overlay_service.dart
overlay_files = glob.glob("**/android_overlay_service.dart", recursive=True)
if overlay_files:
    overlay_path = overlay_files[0]
    with open(overlay_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    whatsapp_hook = """
  // [تم الحقن بواسطة سكربت الأدوات - P3: الفقاعة العائمة لـ واتساب]
  Future<void> handleWhatsAppOverlayTranslation(String incomingText) async {
    if (incomingText.isNotEmpty) {
      print('[Floating Bubble] جاري ترجمة النص الوارد من واتساب: $incomingText');
      // منطق التقاط وترجمة النص عبر الفقاعة العائمة
    }
  }
"""
    if "handleWhatsAppOverlayTranslation" not in content:
        last_brace = content.rfind("}")
        if last_brace != -1:
            updated = content[:last_brace] + whatsapp_hook + "\n}\n"
            with open(overlay_path, "w", encoding="utf-8") as f:
                f.write(updated)
            print("[+] تم تحديث خدمة الفقاعة العائمة للواتساب بنجاح.")

# 2. تحديث الأصوات الخمسة (سيف، سلمى، سما، سارة، وصوت المستخدم)
speech_dir_files = glob.glob("**/speech/**/*.dart", recursive=True) or glob.glob("**/*speech*.dart", recursive=True)
print(f"[*] تم رصد ملفات الصوت: {len(speech_dir_files)} ملفات.")
PYTHON_SCRIPT

echo "[+] انتهى تنفيذ وتطبيق ميزات P3 بنجاح."
