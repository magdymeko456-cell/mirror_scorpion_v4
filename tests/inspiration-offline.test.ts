import { describe, expect, it } from "vitest";

import { buildOfflineLanguagePack, isSupportedOfflineLanguage } from "../server/offline-packs";
import { inspirationCatalog } from "../server/inspiration";
import { legacyOfflineStories } from "../lib/legacy-content";

describe("inspiration and offline data", () => {
  it("builds a real persisted language payload for supported languages", () => {
    const pack = buildOfflineLanguagePack("ar");
    expect(pack.schemaVersion).toBe(1);
    expect(pack.language).toBe("ar");
    expect(pack.mode).toBe("phrase-pack");
    expect(pack.entries.length).toBeGreaterThan(0);
    expect(isSupportedOfflineLanguage("en")).toBe(true);
    expect(isSupportedOfflineLanguage("xx")).toBe(false);
  });

  it("keeps source attribution and downloadable URLs in the catalog", () => {
    expect(inspirationCatalog.length).toBeGreaterThanOrEqual(5);
    for (const item of inspirationCatalog) {
      expect(item.sourceName.length).toBeGreaterThan(3);
      expect(item.sourceUrl.startsWith("https://")).toBe(true);
    }
  });

  it("loads non-empty offline stories carried from the successful build", () => {
    expect(legacyOfflineStories.length).toBeGreaterThan(5);
    expect(legacyOfflineStories.some((item) => item.category.includes("أنبياء"))).toBe(true);
    expect(legacyOfflineStories.some((item) => item.category.includes("أحاديث"))).toBe(true);
    for (const item of legacyOfflineStories.slice(0, 5)) {
      expect(item.title.length).toBeGreaterThan(2);
      expect(item.content.length).toBeGreaterThan(20);
      expect(item.sourceUrl.startsWith("assets/data/")).toBe(true);
    }
  });
});
