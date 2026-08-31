#!/bin/bash
# سكربت مستقل لمزامنة ورفع مشروع Mirror Scorpion على GitHub

echo "[*] جاري تجهيز الملفات للمزامنة..."

# التحقق من وجود مستودع جيت هب
if [ ! -d ".git" ]; then
    echo "[!] مستودع Git غير مهيأ. جاري التهيئة..."
    git init
    git branch -M main
    echo "[!] يرجى إضافة رابط المستودع (Remote URL) لاحقاً إذا لم يكن مضافاً."
fi

# إضافة وتوثيق التعديلات
git add .
git commit -m "feat(P0-P3): إتمام دمج ميزات الصوت، الترجمة، الحماية، وأسباب النزول لمشروع Mirror"

# محاولة الرفع
echo "[*] جاري رفع التعديلات على المستودع..."
git push origin main

if [ $? -eq 0 ]; then
    echo "[+] تم رفع المشروع على GitHub بنجاح!"
else
    echo "[!] تعذر الرفع التلقائي. تأكد من إعداد رابط المستودع (git remote add origin <URL>) أو صلاحيات الدخول."
fi
