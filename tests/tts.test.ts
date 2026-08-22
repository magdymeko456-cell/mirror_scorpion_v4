import { describe, expect, it } from "vitest";
import {
  prepareSpeechText,
  selectVoice,
  speechKey,
  speechLanguageForSide,
  storySpeechText,
} from "../lib/tts";

describe("TTS helpers", () => {
  const voices = [
    { identifier: "ar-sa-premium", language: "ar-SA" },
    { identifier: "en-us-default", language: "en-US" },
  ];

  it("selects an exact locale before falling back to a language prefix", () => {
    expect(selectVoice(voices, "ar-SA")?.identifier).toBe("ar-sa-premium");
    expect(selectVoice([{ identifier: "ar-default", language: "ar" }], "ar-SA")?.identifier).toBe("ar-default");
  });

  it("maps dialogue sides to their spoken languages", () => {
    expect(speechLanguageForSide("right")).toBe("ar-SA");
    expect(speechLanguageForSide("left")).toBe("en-US");
  });

  it("builds readable story text and stable per-item keys", () => {
    expect(storySpeechText("العنوان", "النص")).toBe("العنوان. النص");
    expect(prepareSpeechText("  قصة   هادئة  ")).toBe("قصة هادئة");
    expect(speechKey("story", "7")).toBe("story-7");
  });
});
