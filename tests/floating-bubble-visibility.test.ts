import { describe, expect, it } from "vitest";
import { shouldShowInAppTranslationBubble } from "../lib/floating-bubble-visibility";

describe("floating bubble visibility", () => {
  it("defers to the native Android overlay instead of duplicating a bubble inside the app", () => {
    expect(shouldShowInAppTranslationBubble({ enabled: true, platform: "android", hasNativeOverlay: true })).toBe(false);
  });

  it("keeps a safe in-app fallback on web and on platforms without the native module", () => {
    expect(shouldShowInAppTranslationBubble({ enabled: true, platform: "web", hasNativeOverlay: false })).toBe(true);
    expect(shouldShowInAppTranslationBubble({ enabled: true, platform: "ios", hasNativeOverlay: false })).toBe(true);
    expect(shouldShowInAppTranslationBubble({ enabled: false, platform: "web", hasNativeOverlay: false })).toBe(false);
  });
});
