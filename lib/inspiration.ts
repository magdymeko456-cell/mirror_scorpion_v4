import AsyncStorage from "@react-native-async-storage/async-storage";
import * as FileSystem from "expo-file-system/legacy";
import { Platform } from "react-native";

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

export type DownloadedInspiration = {
  id: string;
  title: string;
  sourceUrl: string;
  localUri?: string;
  downloadedAt: number;
  byteLength: number;
};

const WEB_CACHE_PREFIX = "mirror-scorpion-inspiration-source:";

function safeFileName(value: string) {
  return value.replace(/[^a-zA-Z0-9_-]/g, "-").slice(0, 80) || "source";
}

export function extractInspirationText(payload: unknown): string {
  if (typeof payload === "string") return payload.trim();
  if (Array.isArray(payload)) {
    return payload.map((item) => extractInspirationText(item)).filter(Boolean).join("\n\n");
  }
  if (!payload || typeof payload !== "object") return "";
  const record = payload as Record<string, unknown>;
  const preferredKeys = ["contentAr", "textAr", "text", "summaryAr", "description", "content"];
  const direct = preferredKeys
    .map((key) => record[key])
    .filter((value): value is string => typeof value === "string" && value.trim().length > 0);
  if (direct.length > 0) return direct.join("\n\n");
  const nested = Object.values(record).map((value) => extractInspirationText(value)).filter(Boolean);
  return nested.join("\n\n").slice(0, 80_000);
}

export async function fetchInspirationSource(item: InspirationCatalogItem) {
  const url = item.fullTextUrl || item.sourceUrl;
  const response = await fetch(url, { headers: { Accept: "application/json,text/plain" } });
  if (!response.ok) throw new Error(`تعذر تنزيل المصدر (${response.status})`);
  const raw = await response.text();
  let payload: unknown = raw;
  try {
    payload = JSON.parse(raw);
  } catch {
    // Plain text sources are valid too.
  }
  return {
    id: item.id,
    title: item.titleAr,
    sourceUrl: url,
    raw,
    text: extractInspirationText(payload),
  };
}

export async function downloadInspirationSource(item: InspirationCatalogItem): Promise<DownloadedInspiration> {
  const source = await fetchInspirationSource(item);
  const bytes = new TextEncoder().encode(source.raw).byteLength;

  if (Platform.OS !== "web" && FileSystem.documentDirectory) {
    const directory = `${FileSystem.documentDirectory}mirror-scorpion/inspiration/`;
    await FileSystem.makeDirectoryAsync(directory, { intermediates: true });
    const localUri = `${directory}${safeFileName(item.id)}.json`;
    await FileSystem.writeAsStringAsync(localUri, source.raw, { encoding: FileSystem.EncodingType.UTF8 });
    return { id: item.id, title: item.titleAr, sourceUrl: source.sourceUrl, localUri, downloadedAt: Date.now(), byteLength: bytes };
  }

  await AsyncStorage.setItem(`${WEB_CACHE_PREFIX}${item.id}`, JSON.stringify(source));
  return { id: item.id, title: item.titleAr, sourceUrl: source.sourceUrl, downloadedAt: Date.now(), byteLength: bytes };
}

export async function readDownloadedInspiration(item: InspirationCatalogItem) {
  if (Platform.OS !== "web" && FileSystem.documentDirectory) {
    const localUri = `${FileSystem.documentDirectory}mirror-scorpion/inspiration/${safeFileName(item.id)}.json`;
    const info = await FileSystem.getInfoAsync(localUri);
    if (!info.exists) return null;
    const raw = await FileSystem.readAsStringAsync(localUri, { encoding: FileSystem.EncodingType.UTF8 });
    let payload: unknown = raw;
    try { payload = JSON.parse(raw); } catch {}
    return { id: item.id, title: item.titleAr, sourceUrl: item.sourceUrl, raw, text: extractInspirationText(payload), localUri };
  }
  const cached = await AsyncStorage.getItem(`${WEB_CACHE_PREFIX}${item.id}`);
  return cached ? JSON.parse(cached) as { id: string; title: string; sourceUrl: string; raw: string; text: string } : null;
}
