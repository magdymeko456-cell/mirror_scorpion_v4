export type SpeechLanguage = "ar-SA" | "en-US";

export type AvailableVoice = {
  identifier: string;
  language: string;
};

export const ttsDefaults = {
  rate: 0.92,
  pitch: 1.02,
};

export function normalizeVoiceLanguage(language: string) {
  return language.replace("_", "-").toLowerCase();
}

export function selectVoice(voices: AvailableVoice[], language: SpeechLanguage) {
  const target = normalizeVoiceLanguage(language);
  return voices.find((voice) => normalizeVoiceLanguage(voice.language) === target)
    ?? voices.find((voice) => normalizeVoiceLanguage(voice.language).startsWith(target.slice(0, 2)));
}

export function speechLanguageForSide(side: "left" | "right"): SpeechLanguage {
  return side === "left" ? "en-US" : "ar-SA";
}

export function storySpeechText(title: string, content: string) {
  return `${title}. ${content}`;
}

export function prepareSpeechText(text: string) {
  return text.replace(/\s+/g, " ").trim().slice(0, 3000);
}

export function speechKey(kind: "story" | "message", id: string) {
  return `${kind}-${id}`;
}

export function getSpeechButtonLabel(active: boolean) {
  return active ? "■ إيقاف" : "▶ استمع";
}

export function getSpeechAccessibilityLabel(active: boolean, label: string) {
  return active ? `إيقاف القراءة: ${label}` : `قراءة: ${label}`;
}

export const iosSilentModeNote = "على أجهزة iOS يجب إيقاف الوضع الصامت لسماع القراءة الصوتية.";
