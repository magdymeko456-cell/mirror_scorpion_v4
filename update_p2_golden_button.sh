#!/bin/bash
# سكربت مستقل لإضافة زر وتصميم تفعيل PRO الذهبي في واجهة الميزات

TARGET_FILE="lib/features/feature_hub_screen.dart"

if [ ! -f "$TARGET_FILE" ]; then
    echo "[!] ملف واجهة الميزات غير موجود."
    exit 1
fi

echo "[*] جاري حقن زر تفعيل PRO الذهبي..."

python3 - << 'PYTHON_SCRIPT'
file_path = "lib/features/feature_hub_screen.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# دالة زر PRO الذهبي
golden_pro_widget = """
  // [تم الحقن بواسطة سكربت الأدوات - P2: زر PRO الذهبي]
  Widget buildGoldenProActivationButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 6,
          shadowColor: Colors.amberAccent.withOpacity(0.5),
        ),
        onPressed: () {
          print('تم النقر على زر التفعيل الذهبي لنسخة PRO');
          // تفعيل أو التحقق من الترخيص عبر PremiumVerificationService
        },
        icon: const Icon(Icons.workspace_premium, color: Colors.black, size: 24),
        label: const Text(
          '👑 تفعيل نسخة PRO الذهبية',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
"""

if "buildGoldenProActivationButton" not in content:
    last_brace = content.rfind("}")
    if last_brace != -1:
        updated = content[:last_brace] + golden_pro_widget + "\n}\n"
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(updated)
        print("[+] تم إضافة زر تفعيل PRO الذهبي بنجاح.")
else:
    print("[*] زر تفعيل PRO موجود مسبقاً.")
PYTHON_SCRIPT

echo "[+] انتهى تحديث زر PRO بنجاح."
