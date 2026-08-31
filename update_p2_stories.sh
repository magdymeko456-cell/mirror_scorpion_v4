#!/bin/bash
# سكربت مستقل لإضافة قسم أسباب النزول لكرت القصص القرآنية

TARGET_FILE="lib/features/feature_hub_screen.dart"

if [ ! -f "$TARGET_FILE" ]; then
    echo "[!] ملف واجهة الميزات غير موجود."
    exit 1
fi

echo "[*] جاري إضافة عنصر وقسم 'أسباب النزول' لكرت القصص..."

python3 - << 'PYTHON_SCRIPT'
file_path = "lib/features/feature_hub_screen.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# دالة عرض أسباب النزول داخل كرت القصص
asbab_nuzol_widget = """
  // [تم الحقن بواسطة سكربت الأدوات - P2: أسباب النزول]
  Widget buildAsbabAnNuzolSection() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '📖 أسباب النزول والآيات المرتبطة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amberAccent),
          ),
          SizedBox(height: 6),
          Text(
            'عرض تفصيلي لسبب نزول الآيات مع المؤثرات الصوتية والترجمة بالصوت المختار.',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
"""

if "buildAsbabAnNuzolSection" not in content:
    last_brace = content.rfind("}")
    if last_brace != -1:
        updated = content[:last_brace] + asbab_nuzol_widget + "\n}\n"
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(updated)
        print("[+] تمت إضافة قسم أسباب النزول بنجاح.")
else:
    print("[*] قسم أسباب النزول موجود مسبقاً.")
PYTHON_SCRIPT

echo "[+] انتهى تحديث P2 بنجاح."
