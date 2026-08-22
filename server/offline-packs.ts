import { supportedTranslationLanguages, type TranslationLanguage } from "../shared/languages";

const labels: Record<TranslationLanguage, string> = {
  ar: "العربية",
  en: "English",
  fr: "Français",
  es: "Español",
  de: "Deutsch",
  tr: "Türkçe",
  it: "Italiano",
  pt: "Português",
  ja: "日本語",
  ko: "한국어",
  zh: "中文",
  ru: "Русский",
};

const phraseMap: Record<TranslationLanguage, Record<string, string>> = {
  ar: { Hello: "مرحباً", Welcome: "أهلاً بك", Thanks: "شكراً", "Good morning": "صباح الخير", "Where are you?": "أين أنت؟" },
  en: { Hello: "Hello", Welcome: "Welcome", Thanks: "Thank you", "Good morning": "Good morning", "Where are you?": "Where are you?" },
  fr: { Hello: "Bonjour", Welcome: "Bienvenue", Thanks: "Merci", "Good morning": "Bonjour", "Where are you?": "Où es-tu ?" },
  es: { Hello: "Hola", Welcome: "Bienvenido", Thanks: "Gracias", "Good morning": "Buenos días", "Where are you?": "¿Dónde estás?" },
  de: { Hello: "Hallo", Welcome: "Willkommen", Thanks: "Danke", "Good morning": "Guten Morgen", "Where are you?": "Wo bist du?" },
  tr: { Hello: "Merhaba", Welcome: "Hoş geldiniz", Thanks: "Teşekkürler", "Good morning": "Günaydın", "Where are you?": "Neredesin?" },
  it: { Hello: "Ciao", Welcome: "Benvenuto", Thanks: "Grazie", "Good morning": "Buongiorno", "Where are you?": "Dove sei?" },
  pt: { Hello: "Olá", Welcome: "Bem-vindo", Thanks: "Obrigado", "Good morning": "Bom dia", "Where are you?": "Onde você está?" },
  ja: { Hello: "こんにちは", Welcome: "ようこそ", Thanks: "ありがとう", "Good morning": "おはようございます", "Where are you?": "どこにいますか？" },
  ko: { Hello: "안녕하세요", Welcome: "환영합니다", Thanks: "감사합니다", "Good morning": "좋은 아침입니다", "Where are you?": "어디에 있나요?" },
  zh: { Hello: "你好", Welcome: "欢迎", Thanks: "谢谢", "Good morning": "早上好", "Where are you?": "你在哪里？" },
  ru: { Hello: "Здравствуйте", Welcome: "Добро пожаловать", Thanks: "Спасибо", "Good morning": "Доброе утро", "Where are you?": "Где ты?" },
};

export type OfflineLanguagePack = {
  schemaVersion: 1;
  language: TranslationLanguage;
  name: string;
  generatedAt: string;
  entries: Array<{ source: string; target: string }>;
  mode: "phrase-pack";
  note: string;
};

export function buildOfflineLanguagePack(language: TranslationLanguage): OfflineLanguagePack {
  const entries = Object.entries(phraseMap[language]).map(([source, target]) => ({ source, target }));
  return {
    schemaVersion: 1,
    language,
    name: labels[language],
    generatedAt: new Date().toISOString(),
    entries,
    mode: "phrase-pack",
    note: "حزمة بيانات محلية فعلية. الترجمة العامة غير المحدودة تحتاج محرك ترجمة عصبي مضمناً في نسخة أصلية لاحقة.",
  };
}

export function isSupportedOfflineLanguage(value: string): value is TranslationLanguage {
  return (supportedTranslationLanguages as readonly string[]).includes(value);
}
