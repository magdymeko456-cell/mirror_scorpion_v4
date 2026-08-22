#!/usr/bin/env bash
# ==============================================================================
# Mirror Scorpion v4 - Termux Safe Reset & Git Push Workflow
# ==============================================================================
set -Eeuo pipefail

C_CYN='\033[0;36m'; C_GRN='\033[0;32m'; C_YEL='\033[0;33m'; C_END='\033[0m'
log() { echo -e "${C_CYN}[MIRROR-V4]${C_END} $*"; }
ok()  { echo -e "${C_GRN}  [✔] $*${C_END}"; }
warn(){ echo -e "${C_YEL}  [!] $*${C_END}"; }

WORKDIR="${MIRROR_WORKDIR:-$HOME/mirror_scorpion_v4}"
BACKUP_DIR="${MIRROR_BACKUP_DIR:-$HOME/ms_v4_backup}"

for required in git pnpm npx; do
    if ! command -v "$required" >/dev/null 2>&1; then
        warn "الأداة المطلوبة غير موجودة: $required"
        exit 1
    fi
done

if [ ! -d "$WORKDIR" ]; then
    warn "مجلد المشروع غير موجود في المسار المتوقع: $WORKDIR"
    exit 1
fi
cd "$WORKDIR"

log "1/4. أخذ نسخة احتياطية للملفات الحيوية (lib, app.config.ts, assets, modules, package.json)..."
rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
[ -d "lib" ] && cp -r lib "$BACKUP_DIR/"
[ -d "modules" ] && cp -r modules "$BACKUP_DIR/"
[ -d "assets" ] && cp -r assets "$BACKUP_DIR/"
[ -f "app.config.ts" ] && cp app.config.ts "$BACKUP_DIR/"
[ -f "package.json" ] && cp package.json "$BACKUP_DIR/"
ok "تم حفظ النسخة الاحتياطية بنجاح."

log "2/4. تنظيف المخلفات وملفات الكاش المؤقتة..."
rm -rf .expo .metro .git/index.lock .dart_tool build dist android/.gradle android/build android/app/build ios/build node_modules/.cache 2>/dev/null || true
ok "تم التنظيف بنجاح."

log "3/4. استعادة الموارد والأكواد وتحديث المستودع المحلي..."
[ -d "$BACKUP_DIR/lib" ] && cp -r "$BACKUP_DIR/lib" ./
[ -d "$BACKUP_DIR/modules" ] && cp -r "$BACKUP_DIR/modules" ./
[ -d "$BACKUP_DIR/assets" ] && cp -r "$BACKUP_DIR/assets" ./
[ -f "$BACKUP_DIR/app.config.ts" ] && cp "$BACKUP_DIR/app.config.ts" ./
[ -f "$BACKUP_DIR/package.json" ] && cp "$BACKUP_DIR/package.json" ./

if [ -f "package.json" ] && [ -f "pnpm-lock.yaml" ]; then
    pnpm install --lockfile-only
fi

if [ -f "app.config.ts" ] && [ -d "modules/floating-translator" ]; then
    npx expo prebuild --platform android --no-install
fi

git config http.postBuffer 524288000 2>/dev/null || true
CURRENT_BRANCH="$(git branch --show-current)"
if [ "$CURRENT_BRANCH" != "main" ]; then
    warn "الفرع الحالي هو $CURRENT_BRANCH وليس main؛ لن يتم الدفع لتجنب رفع غير مقصود."
    exit 1
fi

if ! git remote get-url origin >/dev/null 2>&1; then
    warn "لا يوجد remote باسم origin. أضفه أولاً ثم أعد التشغيل."
    exit 1
fi

git add -A
git commit -m "refactor(termux): bootstrap Expo v4 structure and native modules" || echo "لا توجد تغييرات معلقة للالتزام"

log "4/4. دفع التحديثات إلى فرع الرئيسية في GitHub..."
if [ "${FORCE_PUSH:-0}" = "1" ]; then
    warn "FORCE_PUSH=1: سيتم استخدام force-with-lease وليس force العادي."
    git push origin main --force-with-lease
else
    git push origin main
fi
rm -rf "$BACKUP_DIR"

ok "تمت عملية v4 بنجاح! راقب GitHub Actions الآن لبدء البناء الآلي للـ APK."
