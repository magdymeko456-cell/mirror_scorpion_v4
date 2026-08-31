import os

path = "lib/features/feature_hub_screen.dart"
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # استيراد خدمة اختيار الأصوات الصحيحة وتوفير مثيل لها أو استدعاؤها عبر Provider/Context
    if "voice_selection_service.dart" not in content:
        content = "import '../core/services/voice_selection_service.dart';\n" + content

    # تصحيح طريقة استدعاء شيت الأصوات ليطابق VoiceSelectionService بدلاً من SystemTtsService
    old_sheet_call = "builder: (_) => VoiceSelectionSheet(voiceService: _speechService),"
    new_sheet_call = """builder: (_) => VoiceSelectionSheet(
                        voiceService: VoiceSelectionService()..initialize(),
                      ),"""
    
    if old_sheet_call in content:
        content = content.replace(old_sheet_call, new_sheet_call)

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم تصحيح حقن خدمة الأصوات في ملف المحور بنجاح.")
