#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== 1. إنشاء مجلدات الكتب الحقيقية ==="
mkdir -p assets/books/tafseer_jalalayn
mkdir -p assets/books/prophets_stories

echo "=== 2. إضافة المسارات إلى pubspec.yaml ==="
if ! grep -q "assets/books/" pubspec.yaml; then
    # إضافة مسار الكتب تحت قسم assets
    sed -i '/assets:/a \    - assets/books/tafseer_jalalayn/\n    - assets/books/prophets_stories/' pubspec.yaml
    echo "✔ تم تفعيل مسار الكتب في pubspec.yaml"
else
    echo "ℹ المسار مضاف بالفعل."
fi

echo "=== 3. فحص بيئة Flutter ==="
flutter pub get || true
