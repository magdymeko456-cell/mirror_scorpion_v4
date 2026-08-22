import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Localization from "expo-localization";
import { supportedTranslationLanguages, type TranslationLanguage } from "../shared/languages";

export type AppLanguage = "ar" | "en";
export { supportedTranslationLanguages };
export type { TranslationLanguage };

export type LanguagePreferences = {
  appLanguage: AppLanguage;
  sourceLanguage: TranslationLanguage;
  targetLanguage: TranslationLanguage;
};

const STORAGE_KEY = "mirror-scorpion-language-preferences";

export function detectDeviceLanguage(): AppLanguage {
  return Localization.getLocales()[0]?.languageCode?.toLowerCase() === "ar" ? "ar" : "en";
}

export function defaultLanguagePreferences(): LanguagePreferences {
  const appLanguage = detectDeviceLanguage();
  return {
    appLanguage,
    sourceLanguage: appLanguage === "ar" ? "ar" : "en",
    targetLanguage: appLanguage === "ar" ? "en" : "ar",
  };
}

export async function loadLanguagePreferences(): Promise<LanguagePreferences> {
  const fallback = defaultLanguagePreferences();
  try {
    const stored = await AsyncStorage.getItem(STORAGE_KEY);
    if (!stored) return fallback;
    const parsed = JSON.parse(stored) as Partial<LanguagePreferences>;
    return {
      appLanguage: parsed.appLanguage === "en" ? "en" : "ar",
      sourceLanguage: parsed.sourceLanguage ?? fallback.sourceLanguage,
      targetLanguage: parsed.targetLanguage ?? fallback.targetLanguage,
    };
  } catch {
    return fallback;
  }
}

export async function saveLanguagePreferences(preferences: LanguagePreferences) {
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(preferences));
}

export function languageLabel(language: TranslationLanguage, appLanguage: AppLanguage) {
  const labels: Record<TranslationLanguage, { ar: string; en: string }> = {
    ar: { ar: "العربية", en: "Arabic" },
    en: { ar: "الإنجليزية", en: "English" },
    fr: { ar: "الفرنسية", en: "French" },
    es: { ar: "الإسبانية", en: "Spanish" },
    de: { ar: "الألمانية", en: "German" },
    tr: { ar: "التركية", en: "Turkish" },
    it: { ar: "الإيطالية", en: "Italian" },
    pt: { ar: "البرتغالية", en: "Portuguese" },
    ja: { ar: "اليابانية", en: "Japanese" },
    ko: { ar: "الكورية", en: "Korean" },
    zh: { ar: "الصينية", en: "Chinese" },
    ru: { ar: "الروسية", en: "Russian" },
  };
  return labels[language][appLanguage];
}
