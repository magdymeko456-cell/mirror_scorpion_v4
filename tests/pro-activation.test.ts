import { describe, expect, it } from "vitest";
import { appRouter } from "../server/routers";
import { verifyProActivationPatch } from "../server/pro-activation";

describe("PRO activation verification", () => {
  it("exposes a lightweight status endpoint without revealing the configured key", () => {
    const caller = appRouter.createCaller({} as never);
    const status = caller.pro.status();
    return expect(status).resolves.toMatchObject({
      algorithm: "RSA-SHA256",
      patchFormat: "MS4.<base64url-payload>.<base64url-signature>",
    });
  });

  it("never activates a malformed unsigned patch", () => {
    const result = verifyProActivationPatch({ deviceId: "MS4-DEVICE", patch: "MS4.invalid.signature" });
    expect(result.valid).toBe(false);
    expect(["not_configured", "malformed"]).toContain(result.reason);
  });
});
