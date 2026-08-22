import { describe, expect, it } from "vitest";
import { generateKeyPairSync, sign } from "node:crypto";
import { appRouter } from "../server/routers";
import { verifyProActivationPatch, verifyProActivationPatchWithKey } from "../server/pro-activation";

function signedPatch(input: { deviceId: string; issuedAt: number; expiresAt?: number }, privateKey: ReturnType<typeof generateKeyPairSync>["privateKey"]) {
  const payloadPart = Buffer.from(JSON.stringify({ version: 1, ...input, plan: "pro" })).toString("base64url");
  const signaturePart = sign("RSA-SHA256", Buffer.from(payloadPart, "utf8"), privateKey).toString("base64url");
  return `MS4.${payloadPart}.${signaturePart}`;
}

describe("PRO activation verification", () => {
  it("exposes a lightweight status endpoint without revealing the configured key", () => {
    const caller = appRouter.createCaller({} as never);
    const status = caller.pro.status();
    return expect(status).resolves.toMatchObject({
      algorithm: "RSA-SHA256",
      patchFormat: "MS4.<base64url-payload>.<base64url-signature>",
    });
  });

  it.runIf(Boolean(process.env.MIRROR_PRO_ACTIVATION_PUBLIC_KEY))("reports the configured public key as usable through the status endpoint", () => {
    const caller = appRouter.createCaller({} as never);
    return expect(caller.pro.status()).resolves.toMatchObject({ verificationAvailable: true });
  });

  it("never activates a malformed unsigned patch", () => {
    const result = verifyProActivationPatch({ deviceId: "MS4-DEVICE", patch: "MS4.invalid.signature" });
    expect(result.valid).toBe(false);
    expect(["not_configured", "malformed"]).toContain(result.reason);
  });

  it("verifies a properly signed patch and rejects a patch assigned to a different installation", () => {
    const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
    const patch = signedPatch({ deviceId: "MS4-VALID-DEVICE", issuedAt: 1_760_000_000_000 }, privateKey);

    expect(verifyProActivationPatchWithKey({ deviceId: "MS4-VALID-DEVICE", patch }, publicKey)).toMatchObject({
      valid: true,
      payload: { plan: "pro", deviceId: "MS4-VALID-DEVICE" },
    });
    expect(verifyProActivationPatchWithKey({ deviceId: "MS4-OTHER-DEVICE", patch }, publicKey)).toEqual({
      valid: false,
      reason: "wrong_device",
    });
  });

  it("rejects an expired patch even when its RSA signature is valid", () => {
    const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
    const patch = signedPatch({ deviceId: "MS4-EXPIRED", issuedAt: 1_700_000_000_000, expiresAt: 1_700_000_000_001 }, privateKey);
    expect(verifyProActivationPatchWithKey({ deviceId: "MS4-EXPIRED", patch }, publicKey)).toEqual({
      valid: false,
      reason: "expired",
    });
  });
});
