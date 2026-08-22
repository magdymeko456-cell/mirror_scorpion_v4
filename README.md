# Mirror Scorpion v4

تطبيق جوال Expo/React Native بواجهة Royal Dark مستوحاة من تجربة Mirror Scorpion الناجحة، مع أدوات الترجمة والحوار وOCR والقصص والألعاب والإعدادات والفقاعة العائمة الأصلية على Android.

## ما تم دمجه

تم الاحتفاظ بهيكل v3 الحديث، ونقل الهوية البصرية الناجحة وشعار العقرب كعنصر Hero، وإضافة محتوى القصص والأحاديث المحلي من الإصدار الناجح ليعمل أوف لاين بجانب فهرس المصادر البعيدة. كما بقيت مسارات الترجمة والتسجيل وTTS وOCR وLLM والفقاعة العائمة منفصلة عن كود Flutter القديم حتى لا تنتقل تبعياته ومشكلات Gradle الخاصة به.

## التشغيل المحلي

```bash
pnpm install
pnpm check
pnpm test
pnpm lint
pnpm dev
```

## إعادة البناء من Termux

من داخل مجلد المستودع، اجعل السكربت قابلاً للتنفيذ ثم شغّله:

```bash
chmod +x reset_and_push.sh
./reset_and_push.sh
```

يأخذ السكربت نسخة احتياطية من الأكواد والموارد، ينظف مخلفات البناء فقط، يحافظ على تعديلات Android الأصلية، يشغّل Expo Prebuild دون `--clean`، ثم يدفع إلى الفرع `main`. لا يستخدم الدفع القسري افتراضياً. عند الحاجة الاستثنائية وبعد التأكد من حالة الفرع يمكن استخدام `FORCE_PUSH=1 ./reset_and_push.sh`، وسيستعمل `--force-with-lease` فقط.

يمكن تغيير المسار دون تعديل الملف:

```bash
MIRROR_WORKDIR="$HOME/mirror_scorpion_v4" ./reset_and_push.sh
```

## البناء السحابي

يقوم `.github/workflows/build_apk.yml` بتثبيت Node 22 وpnpm 9.12 وJava 17، ثم يشغّل `pnpm install --frozen-lockfile` و`expo prebuild` ويبني APK Release ويرفعه كـ Artifact. Termux لا يحتاج إلى Flutter أو Android SDK لبناء النسخة؛ دوره التحرير والاختبار والرفع فقط.

## ملاحظات مهمة

الفقاعة العائمة تعمل عبر Android Native Overlay Service وتتطلب APK/Development Build وصلاحية الظهور فوق التطبيقات. لا تعمل هذه الخدمة في Expo Web أو Expo Go، ولا تقرأ رسائل WhatsApp أو البريد تلقائياً؛ يصل النص إلى التطبيق فقط عندما يختاره المستخدم عبر Share أو Process Text أو ينسخه ثم يضغط الفقاعة.

الدفع والاشتراكات الرقمية يجب ربطها لاحقاً بمسار متوافق مع Apple App Store وGoogle Play أو RevenueCat، وليس بمجرد مفتاح سري داخل تطبيق العميل.
