import { invokeLLM, listLLMModels } from "./_core/llm";
import { storageGetSignedUrl, storagePut } from "./storage";
import { supportedTranslationLanguages, type TranslationLanguage } from "../shared/languages";

const imageMime = /^(image\/png|image\/jpeg|image\/webp)$/;
const pdfMime = "application/pdf";

function contentToText(content: string | Array<{ type: string; text?: string }>) {
  return Array.isArray(content) ? content.map((part) => part.text ?? "").join("\n") : content;
}

function parseResult(content: string | Array<{ type: string; text?: string }>) {
  const raw = contentToText(content).trim();
  try {
    const parsed = JSON.parse(raw) as { extractedText?: string; translatedText?: string; detectedLanguage?: string };
    return {
      extractedText: parsed.extractedText?.trim() || "",
      translatedText: parsed.translatedText?.trim() || "",
      detectedLanguage: parsed.detectedLanguage?.trim() || "unknown",
    };
  } catch {
    return { extractedText: raw, translatedText: "", detectedLanguage: "unknown" };
  }
}

export async function extractAndTranslateDocument(input: {
  base64: string;
  fileName: string;
  mimeType: string;
  targetLanguage: TranslationLanguage;
}) {
  const bytes = Buffer.from(input.base64, "base64");
  if (!bytes.length) throw new Error("Document file is empty");
  if (bytes.length > 12 * 1024 * 1024) throw new Error("Document exceeds the 12MB limit");
  if (!imageMime.test(input.mimeType) && input.mimeType !== pdfMime) throw new Error("Only PDF, PNG, JPEG, and WEBP documents are supported");

  const safeName = input.fileName.replace(/[^a-zA-Z0-9._-]/g, "_").slice(-120) || "document.pdf";
  const stored = await storagePut(`mirror-scorpion/documents/${Date.now()}-${safeName}`, bytes, input.mimeType);
  const signedUrl = await storageGetSignedUrl(stored.key);
  const { data } = await listLLMModels();
  const preferredModel = data.find((model) => model.id === "gemini-3-flash-preview")?.id ?? data.find((model) => model.id.startsWith("gpt-5"))?.id;
  const attachment = input.mimeType === pdfMime
    ? { type: "file_url" as const, file_url: { url: signedUrl, mime_type: "application/pdf" as const } }
    : { type: "image_url" as const, image_url: { url: signedUrl, detail: "high" as const } };

  const response = await invokeLLM({
    model: preferredModel,
    messages: [
      {
        role: "system",
        content: "You are a careful OCR and document translation assistant. Extract visible text faithfully, preserve paragraphs and headings, do not invent unreadable words, and return JSON only.",
      },
      {
        role: "user",
        content: [
          { type: "text", text: `استخرج النص المرئي من المستند ثم ترجمه إلى ${input.targetLanguage}. أعد JSON بالمفاتيح extractedText, translatedText, detectedLanguage. إذا كان جزء غير مقروء فاكتب [غير مقروء] بدلاً من التخمين. لا تلخص المحتوى.` },
          attachment,
        ],
      },
    ],
    response_format: { type: "json_object" },
    maxTokens: 6000,
  });

  return {
    fileName: input.fileName,
    documentKey: stored.key,
    documentUrl: signedUrl,
    ...parseResult(response.choices[0]?.message?.content ?? ""),
    targetLanguage: input.targetLanguage,
  };
}

export function isSupportedDocumentLanguage(value: string): value is TranslationLanguage {
  return (supportedTranslationLanguages as readonly string[]).includes(value);
}
