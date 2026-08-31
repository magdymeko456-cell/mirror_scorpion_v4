#!/bin/bash
# سكربت دقيق للبحث عن ملفات Gradle (سواء .gradle أو .gradle.kts) وتفعيل الحماية

python3 - << 'PYTHON_SCRIPT'
import os

target_files = []
for root, dirs, files in os.walk("."):
    for file in files:
        if file.startswith("build.gradle"):
            target_files.append(os.path.join(root, file))

if target_files:
    for file_path in target_files:
        if "app" in file_path:  # نركز على ملف التطبيق الداخلي
            print(f"[*] تم العثور على ملف البناء في المسار: {file_path}")
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()

            if "minifyEnabled false" in content:
                content = content.replace("minifyEnabled false", "minifyEnabled true")
                print("[+] تم تعديل minifyEnabled إلى true.")
            elif "minifyEnabled = false" in content:
                content = content.replace("minifyEnabled = false", "minifyEnabled = true")
                print("[+] تم تعديل minifyEnabled = true.")

            if "shrinkResources false" in content:
                content = content.replace("shrinkResources false", "shrinkResources true")
                print("[+] تم تعديل shrinkResources إلى true.")
            elif "shrinkResources = false" in content:
                content = content.replace("shrinkResources = false", "shrinkResources = true")
                print("[+] تم تعديل shrinkResources = true.")

            with open(file_path, "w", encoding="utf-8") as f:
                f.write(content)
            print("[+] تم تحديث حماية التطبيق بنجاح.")
else:
    print("[!] لم يتم العثور على ملفات gradle، قد يكون المشروع بحاجة لإنشاء مجلد android أو أنه بصيغة أخرى.")
PYTHON_SCRIPT
