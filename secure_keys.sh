#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== 1/2. إضافة المفاتيح الحساسة إلى .gitignore ==="
grep -qxF 'serviceAccountKey.json' .gitignore 2>/dev/null || echo 'serviceAccountKey.json' >> .gitignore
grep -qxF 'private_key.pem' .gitignore 2>/dev/null || echo 'private_key.pem' >> .gitignore

echo "=== 2/2. تحديث المستودع محلياً ==="
git add .gitignore
git commit -m "security: ignore firebase and rsa private keys" || echo "لا تغييرات جديدة"

echo "🛡️ تم تأمين الملفات الحساسة ومنع رفعها إلى GitHub بنجاح!"
