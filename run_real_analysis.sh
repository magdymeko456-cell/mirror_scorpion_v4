#!/bin/bash
# البحث عن مسار Flutter الحقيقي وتشغيل التحليل الفعلي

FLUTTER_PATH=""
if command -v flutter &> /dev/null; then
    FLUTTER_PATH="flutter"
elif [ -f "$HOME/flutter/bin/flutter" ]; then
    FLUTTER_PATH="$HOME/flutter/bin/flutter"
elif [ -f "/data/data/com.termux/files/home/flutter/bin/flutter" ]; then
    FLUTTER_PATH="/data/data/com.termux/files/home/flutter/bin/flutter"
else
    # بحث شامل عن مسار flutter bin
    FLUTTER_PATH=$(find ~ -name "flutter" -type f -path "*/bin/flutter" 2>/dev/null | head -n 1)
fi

if [ -n "$FLUTTER_PATH" ]; then
    echo "[*] تم العثور على محرك Flutter في المسار: $FLUTTER_PATH"
    echo "[*] جاري تشغيل التحليل الثابت الحقيقي (Flutter Analyze)..."
    "$FLUTTER_PATH" analyze
else
    echo "[!] لم يتم العثور على مسار Flutter SDK تلقائياً."
    echo "[*] تفقد ما إذا كان مسار الـ SDK في مكان آخر، أو أخبرني بمساره."
fi
