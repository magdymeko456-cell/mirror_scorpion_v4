import { invokeLLM } from "./_core/llm";

export type InspirationCatalogItem = {
  id: string;
  category: "prophets" | "tafsir" | "asbab" | "hadith" | "inspiration";
  titleAr: string;
  titleEn: string;
  summaryAr: string;
  summaryEn: string;
  sourceName: string;
  sourceUrl: string;
  fullTextUrl?: string;
};

const CDN = "https://cdn.jsdelivr.net/gh/mohammed-2-5/islamic-library-data@master";
const TAFSIR_CDN = "https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir";

export const inspirationCatalog: InspirationCatalogItem[] = [
  {
    id: "prophet-index",
    category: "prophets",
    titleAr: "فهرس قصص الأنبياء",
    titleEn: "Prophet Stories Index",
    summaryAr: "فهرس منظم لقصص الأنبياء الخمسة والعشرين مع ملخصات ومراجع قرآنية.",
    summaryEn: "An organized index of twenty-five prophet stories with summaries and Quran references.",
    sourceName: "Islamic App Data — Prophet Stories",
    sourceUrl: `${CDN}/prophet_stories/index.json`,
  },
  {
    id: "prophet-nuh",
    category: "prophets",
    titleAr: "قصة نوح عليه السلام",
    titleEn: "The Story of Prophet Nuh",
    summaryAr: "قصة مفصلة عن الدعوة والصبر وبناء السفينة والدروس المستفادة.",
    summaryEn: "A detailed story of calling, patience, the Ark, and its lessons.",
    sourceName: "Qasas al-Anbiya data — Ibn Kathir attribution",
    sourceUrl: `${CDN}/prophet_stories/nuh.json`,
    fullTextUrl: `${CDN}/prophet_stories/nuh.json`,
  },
  {
    id: "prophet-yusuf",
    category: "prophets",
    titleAr: "قصة يوسف عليه السلام",
    titleEn: "The Story of Prophet Yusuf",
    summaryAr: "محطات الابتلاء والصبر والعفو وحسن التدبير في قصة يوسف عليه السلام.",
    summaryEn: "Trials, patience, forgiveness, and wise leadership in the story of Yusuf.",
    sourceName: "Qasas al-Anbiya data — Ibn Kathir attribution",
    sourceUrl: `${CDN}/prophet_stories/yusuf.json`,
    fullTextUrl: `${CDN}/prophet_stories/yusuf.json`,
  },
  {
    id: "tafseer-fatiha",
    category: "tafsir",
    titleAr: "تفسير آيات مختارة",
    titleEn: "Selected Tafsir Verses",
    summaryAr: "مادة تفسيرية قابلة للتنزيل للقراءة والبحث مع إسناد المصدر.",
    summaryEn: "Downloadable tafsir material for reading and search with source attribution.",
    sourceName: "Tafsir API — published edition catalog",
    sourceUrl: `${TAFSIR_CDN}/en-al-jalalayn/1.json`,
  },
  {
    id: "asbab-al-nuzul",
    category: "asbab",
    titleAr: "أسباب النزول",
    titleEn: "Occasions of Revelation",
    summaryAr: "مصدر مستقل لأسباب النزول مرتبط بالآيات، مع إبقاء الإحالة إلى المصدر الأصلي.",
    summaryEn: "A dedicated occasions-of-revelation source linked to verses with original attribution.",
    sourceName: "Tafsir API — Asbab Al-Nuzul edition",
    sourceUrl: `${TAFSIR_CDN}/en-asbab-al-nuzul-by-al-wahidi/1.json`,
  },
  {
    id: "inspiration-daily",
    category: "inspiration",
    titleAr: "رسائل الثبات والإلهام",
    titleEn: "Steadfastness & Inspiration",
    summaryAr: "رسائل هادئة تساعد المستخدم على التوازن والأمل والعمل دون ادعاء التشخيص أو العلاج.",
    summaryEn: "Gentle messages for balance, hope, and action without diagnosing or treating the user.",
    sourceName: "Mirror Scorpion AI — generated on request",
    sourceUrl: "https://github.com/mohammed-2-5/islamic-library-data",
  },
];

function contentToText(content: string | Array<{ type: string; text?: string }>) {
  return Array.isArray(content) ? content.map((part) => part.text ?? "").join("\n") : content;
}

function parseJson<T>(content: string | Array<{ type: string; text?: string }>, fallback: T): T {
  const raw = contentToText(content).trim();
  try {
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

const safeSystemPrompt = `أنت مساعد إلهام عربي رصين داخل تطبيق Mirror Scorpion. اكتب بلغة محترمة وهادئة، ولا تقدّم تشخيصاً طبياً أو نفسياً، ولا تتوقع حالة المستخدم كحقيقة. امنع الكراهية والتنمر والعنف التفصيلي والألفاظ البذيئة والإيحاءات الجنسية والسخرية المهينة. عند تناول مادة دينية، ميّز بوضوح بين النص المنقول والتأمل الإنساني، ولا تنسب قولاً لمصدر ما لم يرد في النص المدخل.`;

export async function generateInspirationMessage(input: {
  mood?: string;
  focus?: string;
  language: "ar" | "en";
}) {
  const response = await invokeLLM({
    model: "gpt-5-mini",
    messages: [
      { role: "system", content: safeSystemPrompt },
      {
        role: "user",
        content: `أنشئ رسالة إلهام قصيرة من 80 إلى 140 كلمة باللغة ${input.language === "ar" ? "العربية" : "الإنجليزية"}. السياق الذي اختاره المستخدم: ${input.mood || "يحتاج إلى التوازن والسكينة"}. الموضوع الذي يركز عليه: ${input.focus || "الأمل والعمل الهادئ"}. اختم بخطوة عملية صغيرة لليوم، دون وعود أو أحكام قطعية.`,
      },
    ],
    response_format: { type: "json_object" },
    maxTokens: 500,
  });
  const parsed = parseJson<{ message?: string; action?: string }>(response.choices[0]?.message?.content ?? "", {});
  const message = parsed.message?.trim() || contentToText(response.choices[0]?.message?.content ?? "").trim();
  return { message, action: parsed.action?.trim() || "خذ دقيقة هادئة، ثم ابدأ بخطوة واحدة قابلة للإنجاز." };
}

export async function generateStoryVideoScript(input: {
  title: string;
  category: string;
  fullText: string;
  language: "ar" | "en";
}) {
  const boundedText = input.fullText.trim().slice(0, 24000);
  const response = await invokeLLM({
    model: "gpt-5-mini",
    messages: [
      { role: "system", content: safeSystemPrompt },
      {
        role: "user",
        content: `حوّل المادة التالية إلى سيناريو وثائقي طويل باللغة ${input.language === "ar" ? "العربية" : "الإنجليزية"}، مع الحفاظ على التفاصيل وعدم اختلاق أحداث غير موجودة. المطلوب 8 إلى 12 مشهداً، ومجموع مدة مقترح بين 600 و900 ثانية (10 إلى 15 دقيقة). أخرج JSON فقط بالمفاتيح: title, source, fullText, scenes. كل مشهد يحتوي sceneNumber, title, narrativeText, visualPrompt, durationSeconds. اجعل visualPrompt وصفاً بصرياً محترماً بلا تصوير للأنبياء أو الشخصيات المقدسة بشكل مباشر؛ استخدم رموزاً ومشاهد بيئية عند الحاجة. العنوان: ${input.title}. التصنيف: ${input.category}. المادة: ${boundedText}`,
      },
    ],
    response_format: { type: "json_object" },
    maxTokens: 5000,
  });

  const fallback = { title: input.title, source: input.category, fullText: boundedText, scenes: [] as Array<{ sceneNumber: number; title: string; narrativeText: string; visualPrompt: string; durationSeconds: number }> };
  const parsed = parseJson<typeof fallback>(response.choices[0]?.message?.content ?? "", fallback);
  const rawScenes = Array.isArray(parsed.scenes) ? parsed.scenes : [];
  const scenes = rawScenes.slice(0, 12).map((scene, index) => ({
    sceneNumber: index + 1,
    title: String(scene.title || `المشهد ${index + 1}`),
    narrativeText: String(scene.narrativeText || "").trim(),
    visualPrompt: String(scene.visualPrompt || "مشهد وثائقي رمزي هادئ").trim(),
    durationSeconds: Math.max(45, Math.min(150, Number(scene.durationSeconds) || 75)),
  })).filter((scene) => scene.narrativeText.length > 0);

  if (scenes.length === 0) {
    const chunks = boundedText.split(/\n+/).map((part) => part.trim()).filter(Boolean);
    chunks.slice(0, 10).forEach((chunk, index) => scenes.push({
      sceneNumber: index + 1,
      title: `المشهد ${index + 1}: ${input.title}`,
      narrativeText: chunk,
      visualPrompt: "مشهد وثائقي رمزي هادئ مستوحى من المادة المصدرية",
      durationSeconds: 75,
    }));
  }

  while (scenes.length < 8 && scenes.length > 0) {
    const previous = scenes[scenes.length % scenes.length];
    scenes.push({ ...previous, sceneNumber: scenes.length + 1, title: `المشهد ${scenes.length + 1}: متابعة ${input.title}` });
  }

  return {
    storyId: `ai-${Date.now()}`,
    title: String(parsed.title || input.title),
    source: String(parsed.source || input.category),
    fullText: String(parsed.fullText || boundedText),
    scenes,
    createdAt: Date.now(),
    generatedBy: "gpt-5-mini",
  };
}
