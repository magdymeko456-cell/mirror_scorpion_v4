import { invokeLLM } from "./_core/llm";
import { storageGetSignedUrl, storagePut } from "./storage";
import { transcribeAudio } from "./_core/voiceTranscription";
import { supportedTranslationLanguages, type TranslationLanguage } from "../shared/languages";

export { supportedTranslationLanguages } from "../shared/languages";

export type TranslationResult = {
  translatedText: string;
  detectedLanguage?: string;
};

type MyMemoryResponse = {
  responseStatus?: number;
  responseData?: { translatedText?: string };
};

function contentToText(content: string | Array<{ type: string; text?: string }>) {
  return Array.isArray(content) ? content.map((part) => part.text ?? "").join("\n") : content;
}

function parseTranslation(content: string | Array<{ type: string; text?: string }>): TranslationResult {
  const raw = contentToText(content).trim();
  try {
    const parsed = JSON.parse(raw) as Partial<TranslationResult>;
    if (typeof parsed.translatedText === "string" && parsed.translatedText.trim()) {
      return { translatedText: parsed.translatedText.trim(), detectedLanguage: parsed.detectedLanguage };
    }
  } catch {
    // Some models return plain text despite the requested JSON response format.
  }
  if (!raw) throw new Error("The translation service returned an empty response");
  return { translatedText: raw };
}

async function translateWithMyMemory(input: {
  text: string;
  targetLanguage: TranslationLanguage;
  sourceLanguage?: TranslationLanguage | "auto";
}): Promise<TranslationResult> {
  const source = input.sourceLanguage && input.sourceLanguage !== "auto" ? input.sourceLanguage : "ar";
  if (source === input.targetLanguage) return { translatedText: input.text, detectedLanguage: source };

  const query = new URLSearchParams({
    q: input.text,
    langpair: `${source}|${input.targetLanguage}`,
  });
  const response = await fetch(`https://api.mymemory.translated.net/get?${query.toString()}`, {
    headers: { Accept: "application/json" },
  });
  if (!response.ok) throw new Error(`MyMemory request failed with ${response.status}`);
  const data = (await response.json()) as MyMemoryResponse;
  const translatedText = data.responseData?.translatedText?.trim();
  if (!translatedText || data.responseStatus === 403) throw new Error("MyMemory returned no translation");
  return { translatedText, detectedLanguage: source };
}

async function translateWithLLM(input: {
  text: string;
  targetLanguage: TranslationLanguage;
  sourceLanguage?: TranslationLanguage | "auto";
}): Promise<TranslationResult> {
  const response = await invokeLLM({
    messages: [
      {
        role: "system",
        content: "You are a precise professional translator. Preserve meaning, names, tone, punctuation, and line breaks. Return JSON only with translatedText and detectedLanguage.",
      },
      {
        role: "user",
        content: `Translate the following text to ${input.targetLanguage}. Source language: ${input.sourceLanguage ?? "auto-detect"}. Text:\n${input.text}`,
      },
    ],
    response_format: { type: "json_object" },
    max_tokens: 1200,
  });
  return parseTranslation(response.choices[0]?.message?.content ?? "");
}

export async function translateText(input: {
  text: string;
  targetLanguage: TranslationLanguage;
  sourceLanguage?: TranslationLanguage | "auto";
}): Promise<TranslationResult> {
  const text = input.text.trim();
  if (!text) throw new Error("Translation text cannot be empty");

  // The legacy app used MyMemory and felt fast. Keep that path first, then use the built-in LLM when the public service is unavailable or rate-limited.
  try {
    return await translateWithMyMemory({ ...input, text });
  } catch {
    return translateWithLLM({ ...input, text });
  }
}

export async function uploadAndTranslateAudio(input: {
  base64: string;
  fileName: string;
  mimeType: string;
  targetLanguage: TranslationLanguage;
  sourceLanguage?: TranslationLanguage | "auto";
}) {
  const audio = Buffer.from(input.base64, "base64");
  if (!audio.length) throw new Error("Audio file is empty");
  if (audio.length > 16 * 1024 * 1024) throw new Error("Audio file exceeds the 16MB limit");
  if (!input.mimeType.startsWith("audio/")) throw new Error("Only audio files are supported");

  const safeName = input.fileName.replace(/[^a-zA-Z0-9._-]/g, "_").slice(-120) || "recording.m4a";
  const stored = await storagePut(`mirror-scorpion/audio/${Date.now()}-${safeName}`, audio, input.mimeType);
  const signedUrl = await storageGetSignedUrl(stored.key);
  const transcription = await transcribeAudio({
    audioUrl: signedUrl,
    language: input.sourceLanguage === "auto" ? undefined : input.sourceLanguage,
  });
  if ("error" in transcription) throw new Error(transcription.details ? `${transcription.error}: ${transcription.details}` : transcription.error);

  const translation = await translateText({
    text: transcription.text,
    targetLanguage: input.targetLanguage,
    sourceLanguage: input.sourceLanguage === "auto" ? transcription.language as TranslationLanguage : input.sourceLanguage,
  });

  return {
    fileName: input.fileName,
    audioKey: stored.key,
    audioUrl: signedUrl,
    transcription: transcription.text,
    detectedLanguage: transcription.language,
    translatedText: translation.translatedText,
  };
}
