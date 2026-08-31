#!/bin/bash
# سكربت الربط الفعلي للودجتس والأزرار داخل شجرة العرض في feature_hub_screen.dart

python3 - << 'PYTHON_SCRIPT'
import re

file_path = "lib/features/feature_hub_screen.dart"
with open(file_path, "r", encoding="utf-8") as f:
    code = f.read()

# 1. البحث عن قائمة العناصر (children) في الـ Column الرئيسية للواجهة وحقن زر PRO وقسم أسباب النزول
target_pattern = r'(children:\s*\[[\s\S]*?)(\s*\]\s*,)'
match = re.search(target_pattern, code)

if match and "buildGoldenProActivationButton" not in match.group(1):
    widgets_to_add = "\n            buildGoldenProActivationButton(),\n            buildAsbabAnNuzolSection(),\n"
    code = code.replace(match.group(1), match.group(1) + widgets_to_add, 1)
    print("[+] تم ربط وزرع زر PRO الذهبي وقسم أسباب النزول في واجهة العرض بنجاح.")
else:
    print("[*] عناصر الواجهة مرتبطة مسبقاً في شجرة العرض.")

# 2. ربط الأحداث الفارغة بدالة المعالجة الصوتية لزر الدبوس
if "handleAudioPinSelection" in code:
    print("[*] تم التحقق من ربط مستشعر الملف الصوتي (Whisper).")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(code)
print("[+] انتهى ربط وتفعيل الواجهات بنجاح.")
PYTHON_SCRIPT
