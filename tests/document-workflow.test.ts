import { afterEach, describe, expect, it, vi } from "vitest";
import {
  MINIMUM_DOCUMENT_PROCESSING_MS,
  normalizeDocumentUrl,
  waitForMinimumDocumentProcessing,
} from "../lib/document-workflow";

describe("document workflow", () => {
  afterEach(() => vi.useRealTimers());

  it("normalizes only safe HTTP(S) document links", () => {
    expect(normalizeDocumentUrl("example.com/file.pdf")).toBe("https://example.com/file.pdf");
    expect(normalizeDocumentUrl("https://example.com/file.pdf")).toBe("https://example.com/file.pdf");
    expect(normalizeDocumentUrl("ftp://example.com/file.pdf")).toBeNull();
    expect(normalizeDocumentUrl(" ")).toBeNull();
  });

  it("keeps the document-processing state visible for at least three seconds", async () => {
    vi.useFakeTimers();
    const completion = waitForMinimumDocumentProcessing();
    await vi.advanceTimersByTimeAsync(MINIMUM_DOCUMENT_PROCESSING_MS - 1);
    let completed = false;
    void completion.then(() => { completed = true; });
    await Promise.resolve();
    expect(completed).toBe(false);
    await vi.advanceTimersByTimeAsync(1);
    await completion;
    expect(completed).toBe(true);
  });
});
