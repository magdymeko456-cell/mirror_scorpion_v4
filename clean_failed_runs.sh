#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v4"
cd "$WORKDIR"

echo "=== 1. فحص وجود أدوات GitHub CLI ==="
if ! command -v gh &> /dev/null; then
    echo "⚡ جاري تثبيت github-cli..."
    pkg install gh -y
fi

echo "=== 2. مسح كافة سجلات البناء الفاشلة (Failed Runs) ==="

# جلب معرفات التشغيل الفاشلة وحذفها واحداً تلو الآخر
gh run list --status failure --limit 100 --json databaseId -q '.[].databaseId' | while read -r run_id; do
    if [ -n "$run_id" ]; then
        echo "🗑 جاري حذف البناء الفاشل رقم: $run_id"
        gh run delete "$run_id" || true
    fi
done

echo "🚀 تم تنظيف كافة البناءات الفاشلة من المستودع بنجاح!"
