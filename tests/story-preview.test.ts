import { describe, expect, it } from "vitest";
import { storyNeedsExpansion, storyPreview } from "../lib/story-preview";

describe("story preview", () => {
  it("keeps short offline stories readable without a false truncation marker", () => {
    expect(storyPreview("قصة قصيرة وهادفة.")).toBe("قصة قصيرة وهادفة.");
    expect(storyNeedsExpansion("قصة قصيرة وهادفة.")).toBe(false);
  });

  it("truncates long stories at a word boundary and exposes the more state", () => {
    const content = Array.from({ length: 180 }, () => "كلمة").join(" ");
    const preview = storyPreview(content, 120);
    expect(preview.endsWith("…")).toBe(true);
    expect(preview.length).toBeLessThanOrEqual(121);
    expect(storyNeedsExpansion(content, 120)).toBe(true);
  });
});
