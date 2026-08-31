#!/bin/bash
# سكربت مستقل لتعديل خدمة ML Kit وضمان تحميل النموذج أول مرة

TARGET_FILE="core/mlkit/on_device_translation_service.dart"

if [ ! -f "$TARGET_FILE" ]; then
    # البحث عن الملف لو المسار فرعي مختصلف
    TARGET_FILE=$(find lib -name "on_device_translation_service.dart")
fi

if [ -z "$TARGET_FILE" ]; then
    echo "[!] تنبيه: ملف خدمة ML Kit غير موجود."
    exit 1
fi

echo "[*] جاري تحديث ملف خدمة الترجمة المحلية لتحميل النموذج تلقائياً..."

python3 - << 'PYTHON_SCRIPT'
import glob

files = glob.glob("**/on_device_translation_service.dart", recursive=True)
if not files:
    exit(0)

file_path = files[0]
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# إضافة فحص وتنزيل النموذج لو لم يكن متوفراً
download_logic = """
  // [تم الحقن بواسطة سكربت الأدوات - P1]
  Future<void> ensureModelDownloaded(String sourceLang, String targetLang) async {
    final modelManager = OnDeviceTranslatorModelManager();
    // التحقق وتحميل النماذج تلقائياً عند الاستخدام الأول
    bool sourceDownloaded = await modelManager.isModelDownloaded(sourceLang);
    if (!sourceDownloaded) {
      await modelManager.downloadModel(sourceLang);
    }
    bool targetDownloaded = await modelManager.isModelDownloaded(targetLang);
    if (!targetDownloaded) {
      await modelManager.downloadModel(targetLang);
    }
  }
"""

if "ensureModelDownloaded" not in content:
    last_brace = content.rfind("}")
    if last_brace != -1:
        updated = content[:last_brace] + download_logic + "\n}\n"
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(updated)
        print("[+] تم تحديث خدمة ML Kit بنجاح.")
else:
    print("[*] دالة التحميل موجودة مسبقاً.")
PYTHON_SCRIPT

echo "[+] انتهى تحديث P1 بنجاح."
