#!/bin/bash
# سكربت مستقل لتطبيق وحقن حلول P0 في مشروع Mirror Scorpion

TARGET_FILE="lib/features/feature_hub_screen.dart"

if [ ! -f "$TARGET_FILE" ]; then
    echo "[!] تنبيه: ملف $TARGET_FILE غير موجود في المسار الحالي."
    exit 1
fi

echo "[*] جاري فحقن وتحديث دوال P0 (الميكروفون و Whisper) في ملف الواجهة..."

# استخدام بايثون للحقن الآمن داخل كلاس الواجهة دون تخريب الهيكلة
python3 - << 'PYTHON_SCRIPT'
import os

file_path = "lib/features/feature_hub_screen.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# الدوال البرمجية الجديدة للحلول
p0_methods = """
  // [تم الحقن تلقائياً بواسطة سكربت الأدوات المستقل - P0]
  Future<void> updateSourceLanguageAndResetMic(String newLanguageCode) async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      setState(() {
        currentSourceLanguage = newLanguageCode;
      });
      bool available = await _speechToText.initialize(
        onError: (error) => print('خطأ في الميكروفون: $error'),
        onStatus: (status) => print('حالة الميكروفون: $status'),
      );
      if (available) {
        print('تم إعادة ضبط الميكروفون بنجاح للغة: $currentSourceLanguage');
      }
    } catch (e) {
      print('خطأ أثناء إعادة ضبط الميكروفون: $e');
    }
  }

  Future<void> handleAudioPinSelection() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result != null && result.files.single.path != null) {
        String audioPath = result.files.single.path!;
        print('جاري معالجة الملف الصوتي عبر Whisper: $audioPath');
        final whisperService = Provider.of<WhisperService>(context, listen: false);
        String transcriptionResult = await whisperService.transcribeAudio(audioPath);
        setState(() {
          inputController.text = transcriptionResult;
        });
      }
    } catch (e) {
      print('خطأ في معالجة ملف Whisper الصوتي: $e');
    }
  }
"""

# التحقق من عدم تكرار الدوال قبل إضافتها قبل آخر قوس اغلاق }
if "updateSourceLanguageAndRecovery" not in content and "updateSourceLanguageAndResetMic" not in content:
    # إدراج الدوال قبل قوس الإغلاق الأخير للملف
    last_brace_index = content.rfind("}")
    if last_brace_index != -1:
        updated_content = content[:last_brace_index] + p0_methods + "\n}\n"
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(updated_content)
        print("[+] تم تحديث كود P0 بنجاح داخل الملف.")
    else:
        print("[!] لم يتم العثور على هيكلة القوس الصحيحة في الملف.")
else:
    print("[*] دوال P0 موجودة مسبقاً في الملف.")
PYTHON_SCRIPT

echo "[+] انتهى تنفيذ سكربت التحديث بنجاح."
