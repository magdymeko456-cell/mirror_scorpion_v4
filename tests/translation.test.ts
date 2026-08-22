import { describe, expect, it } from "vitest";
import { supportedTranslationLanguages } from "../shared/languages";

describe("translation configuration", () => {
  it("keeps Arabic and English available for the default flow", () => {
    expect(supportedTranslationLanguages).toContain("ar");
    expect(supportedTranslationLanguages).toContain("en");
  });

  it("contains the supported language set used by the translation API", () => {
    expect(supportedTranslationLanguages).toEqual(["ar", "en", "fr", "es", "de", "tr", "it", "pt", "ja", "ko", "zh", "ru"]);
  });
});
