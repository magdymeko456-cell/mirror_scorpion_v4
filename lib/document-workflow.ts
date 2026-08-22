export const MINIMUM_DOCUMENT_PROCESSING_MS = 3_000;

/** ينتظر الحد الأدنى المرئي للمعالجة دون إخفاء زمن OCR الفعلي إن كان أطول. */
export function waitForMinimumDocumentProcessing(duration = MINIMUM_DOCUMENT_PROCESSING_MS) {
  return new Promise<void>((resolve) => setTimeout(resolve, duration));
}

/** يقبل فقط رابط HTTP(S) صالحاً حتى لا يحاول التطبيق فتح مسارات أو مخططات غير آمنة. */
export function normalizeDocumentUrl(value: string): string | null {
  const candidate = value.trim();
  if (!candidate) return null;

  try {
    const hasExplicitScheme = /^[a-zA-Z][a-zA-Z\d+.-]*:/.test(candidate);
    const url = new URL(hasExplicitScheme ? candidate : `https://${candidate}`);
    return url.protocol === "https:" || url.protocol === "http:" ? url.toString() : null;
  } catch {
    return null;
  }
}
