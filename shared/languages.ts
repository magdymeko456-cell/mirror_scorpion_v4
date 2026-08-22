export const supportedTranslationLanguages = ["ar", "en", "fr", "es", "de", "tr", "it", "pt", "ja", "ko", "zh", "ru"] as const;
export type TranslationLanguage = (typeof supportedTranslationLanguages)[number];
