const falVideoGatewayMode = 'disabled-by-default';
const falVideoModel = 'fal-ai/wan-25-preview/text-to-video';
const falVideoDurationSeconds = 5;
const falVideoResolution = '480p';

function buildFalVideoGatewayStatus({
  authenticated = false,
  hasApiKey = false,
  monthlyCapUsd = 0,
  dailyJobLimit = 0,
} = {}) {
  return {
    provider: 'Fal',
    gatewayMode: falVideoGatewayMode,
    model: falVideoModel,
    enabled: false,
    externalCallsAllowed: false,
    authenticated,
    hasApiKey,
    monthlyCapUsd,
    dailyJobLimit,
    message:
      'Fal video gateway is intentionally disabled. No story, image, audio, or video is sent to Fal.',
  };
}

function validateFutureFalVideoRequest({
  gatewayEnabled = false,
  hasApiKey = false,
  userId,
  consentReceiptId,
  quotaRemaining = 0,
  durationSeconds = falVideoDurationSeconds,
  resolution = falVideoResolution,
} = {}) {
  if (!gatewayEnabled) return { allowed: false, code: 'GATEWAY_DISABLED' };
  if (!hasApiKey) return { allowed: false, code: 'SERVER_SECRET_MISSING' };
  if (typeof userId !== 'string' || userId.length === 0) {
    return { allowed: false, code: 'AUTH_REQUIRED' };
  }
  if (!consentReceiptId) return { allowed: false, code: 'CONSENT_REQUIRED' };
  if (quotaRemaining <= 0) return { allowed: false, code: 'QUOTA_EXHAUSTED' };
  if (durationSeconds !== falVideoDurationSeconds || resolution !== falVideoResolution) {
    return { allowed: false, code: 'TRIAL_SCOPE_EXCEEDED' };
  }
  return { allowed: true, code: 'APPROVED_FOR_PROVIDER_CALL' };
}

module.exports = {
  buildFalVideoGatewayStatus,
  falVideoDurationSeconds,
  falVideoGatewayMode,
  falVideoModel,
  falVideoResolution,
  validateFutureFalVideoRequest,
};
