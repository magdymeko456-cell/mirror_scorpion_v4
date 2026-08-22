import { createPublicKey, type KeyObject, verify } from "node:crypto";

export type ProActivationPayload = {
  version: 1;
  deviceId: string;
  issuedAt: number;
  expiresAt?: number;
  plan: "pro";
};

type ProVerificationResult = {
  valid: boolean;
  reason?: "not_configured" | "malformed" | "invalid_signature" | "wrong_device" | "expired";
  payload?: ProActivationPayload;
};

const PUBLIC_KEY_ENV = "MIRROR_PRO_ACTIVATION_PUBLIC_KEY";

function publicKey() {
  const value = process.env[PUBLIC_KEY_ENV]?.trim().replace(/(?:\\r)?\\n/g, "\n");
  if (!value) return null;
  try {
    const key = createPublicKey(value);
    return key.asymmetricKeyType === "rsa" ? key : null;
  } catch {
    return null;
  }
}

export function getProVerificationStatus() {
  return {
    verificationAvailable: Boolean(publicKey()),
    algorithm: "RSA-SHA256" as const,
    patchFormat: "MS4.<base64url-payload>.<base64url-signature>",
  };
}

function decodePayload(value: string): ProActivationPayload | null {
  try {
    const parsed = JSON.parse(Buffer.from(value, "base64url").toString("utf8")) as Partial<ProActivationPayload>;
    if (
      parsed.version !== 1 ||
      typeof parsed.deviceId !== "string" ||
      typeof parsed.issuedAt !== "number" ||
      parsed.plan !== "pro" ||
      (parsed.expiresAt !== undefined && typeof parsed.expiresAt !== "number")
    ) {
      return null;
    }
    return parsed as ProActivationPayload;
  } catch {
    return null;
  }
}

export function verifyProActivationPatchWithKey(input: { deviceId: string; patch: string }, key: KeyObject): ProVerificationResult {
  const [prefix, payloadPart, signaturePart, extra] = input.patch.trim().split(".");
  if (prefix !== "MS4" || !payloadPart || !signaturePart || extra || input.patch.length > 8_192) {
    return { valid: false, reason: "malformed" };
  }

  const payload = decodePayload(payloadPart);
  if (!payload) return { valid: false, reason: "malformed" };
  const signatureIsValid = verify(
    "RSA-SHA256",
    Buffer.from(payloadPart, "utf8"),
    key,
    Buffer.from(signaturePart, "base64url"),
  );
  if (!signatureIsValid) return { valid: false, reason: "invalid_signature" };
  if (payload.deviceId !== input.deviceId) return { valid: false, reason: "wrong_device" };
  if (payload.expiresAt !== undefined && payload.expiresAt < Date.now()) return { valid: false, reason: "expired" };

  return { valid: true, payload };
}

export function verifyProActivationPatch(input: { deviceId: string; patch: string }): ProVerificationResult {
  const key = publicKey();
  if (!key) return { valid: false, reason: "not_configured" };
  return verifyProActivationPatchWithKey(input, key);
}
