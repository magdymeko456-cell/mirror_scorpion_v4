#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== 1/4. تسجيل الخروج من الحساب القديم ==="
gh auth logout -h github.com 2>/dev/null || true

echo "=== 2/4. تسجيل الدخول عبر المتصفح (Web Flow) ==="
echo "سيظهر لك رمز (Code) الآن، انسخه وافتحه في المتصفح لتأكيد الحساب:"
gh auth login -h github.com -p https -w

echo "=== 3/4. تهيئة Git لاستخدام اعتمادات GitHub CLI ==="
gh auth setup-git

echo "=== 4/4. رفع التعديلات إلى الفرع الرئيسي main ==="
git push origin main

echo "🚀 تم رفع كافة التعديلات وتأمين المستودع بنجاح!"
