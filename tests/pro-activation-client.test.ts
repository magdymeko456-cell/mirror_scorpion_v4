import { describe, expect, it } from "vitest";
import { createProInstallationId, isSignedProPatch, normalizeProPatch } from "../lib/pro-activation-client";

describe("PRO activation client", () => {
  it("creates a local installation identifier without reading hardware identifiers", () => {
    expect(createProInstallationId(1_760_000_000_000)).toMatch(/^MS4-[A-Z0-9]+-[A-Z0-9]{10}$/);
  });

  it("accepts only the documented signed-patch envelope before contacting the server", () => {
    expect(normalizeProPatch(" MS4.payload.signature ")).toBe("MS4.payload.signature");
    expect(isSignedProPatch("MS4.abcdefghijkl.abcdefghijklmnopqrstuvwxyz0123456789_-" )).toBe(true);
    expect(isSignedProPatch("1234567890123456789012345")).toBe(false);
  });
});
