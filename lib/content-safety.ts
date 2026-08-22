const forbiddenKeywords = [
  "عنف", "قتل", "شتيمة", "حقير", "سخيف", "تنمر", "عدوان",
  "kill", "hate", "abuse", "violence", "stupid", "idiot"
];

export function checkContentSafety(text: string): { safe: boolean; reason?: string } {
  const normalized = text.toLowerCase();
  for (const word of forbiddenKeywords) {
    if (normalized.includes(word)) {
      return {
        safe: false,
        reason: "المحتوى يخالف معايير الأمان والاحترام (يُمنع العنف، الكراهية، الألفاظ البذيئة أو التنمر)."
      };
    }
  }
  return { safe: true };
}
