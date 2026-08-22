export type LegacyOfflineStory = {
  id: string;
  category: string;
  title: string;
  content: string;
  sourceName: string;
  sourceUrl: string;
};

type ProphetRecord = {
  id?: string;
  category?: string;
  title?: string;
  text_ar?: string;
  source?: string;
  lessons?: string[];
};

type ShortStoryRecord = {
  id?: string;
  category?: string;
  title?: string;
  content?: string;
  lessons?: string;
};

type HadithRecord = {
  id?: number | string;
  text_ar?: string;
  explanation_ar?: string;
  source?: string;
};

type QuranStoriesPayload = { prophets?: ProphetRecord[] };

const quranStories = require("../assets/data/quran_stories.json") as QuranStoriesPayload;
const shortStories = require("../assets/data/stories.json") as ShortStoryRecord[];
const hadithQudsi = require("../assets/data/hadith_qudsi.json") as HadithRecord[];

const clean = (value: unknown) => (typeof value === "string" ? value.trim() : "");

const prophetItems: LegacyOfflineStory[] = (quranStories.prophets ?? [])
  .map((story, index) => {
    const title = clean(story.title) || `قصة نبي ${index + 1}`;
    const content = clean(story.text_ar);
    if (!content) return null;
    const lessons = Array.isArray(story.lessons) && story.lessons.length > 0
      ? `\n\nالدروس: ${story.lessons.join("، ")}`
      : "";
    return {
      id: `offline-prophet-${clean(story.id) || index + 1}`,
      category: clean(story.category) || "قصص الأنبياء",
      title,
      content: `${content}${lessons}`,
      sourceName: clean(story.source) || "القصص القرآنية — محتوى v2 المحلي",
      sourceUrl: "assets/data/quran_stories.json",
    };
  })
  .filter((item): item is LegacyOfflineStory => item !== null);

const shortStoryItems: LegacyOfflineStory[] = shortStories
  .map((story, index) => {
    const title = clean(story.title) || `قصة محلية ${index + 1}`;
    const content = clean(story.content);
    if (!content) return null;
    return {
      id: `offline-story-${clean(story.id) || index + 1}`,
      category: clean(story.category) || "قصص مختارة",
      title,
      content: `${content}${clean(story.lessons) ? `\n\nالدروس: ${clean(story.lessons)}` : ""}`,
      sourceName: "قصص v2 المحلية — للمطالعة أوف لاين",
      sourceUrl: "assets/data/stories.json",
    };
  })
  .filter((item): item is LegacyOfflineStory => item !== null);

const hadithItems: LegacyOfflineStory[] = hadithQudsi
  .map((hadith, index) => {
    const text = clean(hadith.text_ar);
    if (!text) return null;
    return {
      id: `offline-hadith-qudsi-${hadith.id ?? index + 1}`,
      category: "أحاديث قدسية",
      title: `حديث قدسي ${index + 1}`,
      content: `${text}${clean(hadith.explanation_ar) ? `\n\nشرح مختصر: ${clean(hadith.explanation_ar)}` : ""}`,
      sourceName: clean(hadith.source) || "الأحاديث القدسية — محتوى v2 المحلي",
      sourceUrl: "assets/data/hadith_qudsi.json",
    };
  })
  .filter((item): item is LegacyOfflineStory => item !== null);

/** Offline material carried from the successful v2 build; no network is required. */
export const legacyOfflineStories: LegacyOfflineStory[] = [
  ...prophetItems,
  ...shortStoryItems,
  ...hadithItems,
];
