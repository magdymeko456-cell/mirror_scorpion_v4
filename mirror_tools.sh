#!/bin/bash
# سكربت منفصل للمكتبات والأدوات الخاصة بمشروع Mirror Scorpion

if ! command -v proot-distro &> /dev/null; then
    pkg install -y proot-distro
fi

# التحقق من حالة تثبيت أوبونتو بشكل سليم دون أخطاء تكرار الحاوية
if ! proot-distro list | grep -q "ubuntu.*installed"; then
    echo "[*] جاري تثبيت بيئة أوبونتو الافتراضية..."
    proot-distro install ubuntu
fi

FLUTTER_PATH="/root/flutter/bin"

# التحقق من وجود محرك فلاتر داخل الحاوية وتثبيته إذا لم يكن موجوداً
if ! proot-distro login ubuntu -- [ -d "/root/flutter" ]; then
    echo "[*] جاري إعداد وتثبيت محرك Flutter داخل البيئة الافتراضية..."
    proot-distro login ubuntu -- bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y curl git unzip xz-utils libglu1-mesa && git clone https://github.com/flutter/flutter.git -b stable /root/flutter"
fi

echo "[*] جاري تنفيذ جلب تبعيات المشروع (flutter pub get) عبر البيئة المتوافقة..."
proot-distro login ubuntu -- bash -c "export PATH=\$PATH:$FLUTTER_PATH && cd $(pwd) && flutter pub get"

echo "[+] تمت تهيئة وتحديث كافة مكتبات وأدوات المشروع في السكربت المستقل بنجاح!"
