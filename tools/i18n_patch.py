#!/usr/bin/env python3
"""مسح/ترقيع النصوص العربية في ملف هدف واحد.
  python3 tools/i18n_patch.py --report                     # قائمة النصوص وسطورها
  python3 tools/i18n_patch.py --map i18n_map.json          # dry-run
  python3 tools/i18n_patch.py --map i18n_map.json --apply  # كتابة فعلية
"""
import argparse, json, re, sys, pathlib

TARGET = pathlib.Path("lib/features/feature_hub_screen.dart")
IMPORT = "import '../l10n/generated/app_localizations.dart';"
AR = re.compile(r"'([^']*[\u0600-\u06FF][^']*)'")
MAP_ENTRY = re.compile(r"^\s*'[^']*'\s*:")          # مدخلات قواميس بيانات — تُستثنى
ARABIC = re.compile(r"[\u0600-\u06FF]")

def scan(text):
    out = []
    for i, line in enumerate(text.splitlines(), 1):
        if MAP_ENTRY.match(line):
            continue
        for m in AR.finditer(line):
            s = m.group(1)
            if len(s.strip()) >= 2:
                out.append((i, s))
    return out

def patch(text, mapping):
    lines = text.splitlines(keepends=True)
    changed = []
    for i, line in enumerate(lines):
        orig = line
        for s, key in mapping.items():
            line = line.replace("'" + s + "'", f"AppLocalizations.of(context)!.{key}")
        if line != orig:
            # إسقاط const الصار غير صالح على نفس السطر فقط
            line = re.sub(r"\bconst\s+(?=Text\(|SnackBar\(|Tooltip\()", "", line)
            changed.append((i + 1, orig.strip(), line.strip()))
        lines[i] = line
    new = "".join(lines)
    if IMPORT not in new:                                # حقن الاستيراد بعد آخر import
        ls = new.splitlines(keepends=True)
        last = max(i for i, l in enumerate(ls) if l.startswith("import "))
        ls.insert(last + 1, IMPORT + "\n")
        new = "".join(ls)
    return new, changed

p = argparse.ArgumentParser()
p.add_argument("--report", action="store_true")
p.add_argument("--map")
p.add_argument("--apply", action="store_true")
a = p.parse_args()

text = TARGET.read_text(encoding="utf-8")
if a.report:
    for i, s in scan(text):
        print(f"{i}: {s}")
    sys.exit(0)

mapping = json.loads(pathlib.Path(a.map).read_text(encoding="utf-8"))
found = {s for _, s in scan(text)}
missing = [s for s in mapping if s not in found]
leftover = [s for _, s in scan(text) if s not in mapping]
if missing:  print(f"⚠ في الخريطة وغير موجودة بالملف: {missing}")
if leftover: print(f"⚠ ست بقى بلا ترجمة: {len(leftover)}")

new, changed = patch(text, mapping)
print(f"{'سيُكتب' if a.apply else 'DRY-RUN'}: {len(changed)} سطراً ستتغير")
for i, o, n in changed[:25]:
    print(f"  L{i}: {o[:90]}\n    → {n[:90]}")
if a.apply:
    TARGET.write_text(new, encoding="utf-8")
    print("✓ كُتب الملف")
