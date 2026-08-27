#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== 1. إنشاء مجلدات حفظ الكتب الثابتة ==="
mkdir -p assets/books/tafseer_jalalayn
mkdir -p assets/books/prophets_stories

echo "=== 2. توثيق وحفظ الكتب في المسارات المخصصة ==="

# إنشاء ملف هيكلي لتفسير الجلالين
cat << 'JSON' > assets/books/tafseer_jalalayn/data.json
{
  "book_name": "تفسير الجلالين",
  "source_url": "https://ketabonline.com/ar/books/1484",
  "version": "1.0.0",
  "chapters": []
}
JSON

# إنشاء ملف هيكلي لقصص الأنبياء
cat << 'JSON' > assets/books/prophets_stories/data.json
{
  "book_name": "قصص الأنبياء - تحقيق عبد الواحد",
  "source_url": "https://waqfeya.net/books/9d00a9b10a8049e2a1149ff04cb78a6d",
  "version": "1.0.0",
  "stories": []
}
JSON

echo "✔ تم إنشاء وحفظ هياكل الكتب بنجاح في assets/books/"
