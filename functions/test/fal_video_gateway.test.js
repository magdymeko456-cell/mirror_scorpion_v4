const assert = require('node:assert/strict');
const test = require('node:test');

const {
  buildFalVideoGatewayStatus,
  falVideoGatewayMode,
  validateFutureFalVideoRequest,
} = require('../src/fal_video_gateway');

test('Fal gateway stays disabled even if a future secret and quota exist', () => {
  const status = buildFalVideoGatewayStatus({
    authenticated: true,
    hasApiKey: true,
    monthlyCapUsd: 25,
    dailyJobLimit: 2,
  });

  assert.equal(status.gatewayMode, falVideoGatewayMode);
  assert.equal(status.enabled, false);
  assert.equal(status.externalCallsAllowed, false);
  assert.match(status.message, /No story, image, audio, or video is sent/);
});

test('Fal rejects a future request before any provider condition when disabled', () => {
  const result = validateFutureFalVideoRequest({
    gatewayEnabled: false,
    hasApiKey: true,
    userId: 'owner-1',
    consentReceiptId: 'consent-1',
    quotaRemaining: 1,
  });

  assert.deepEqual(result, { allowed: false, code: 'GATEWAY_DISABLED' });
});

test('Fal future request is constrained to the reviewed trial format', () => {
  const result = validateFutureFalVideoRequest({
    gatewayEnabled: true,
    hasApiKey: true,
    userId: 'owner-1',
    consentReceiptId: 'consent-1',
    quotaRemaining: 1,
    durationSeconds: 10,
    resolution: '720p',
  });

  assert.deepEqual(result, { allowed: false, code: 'TRIAL_SCOPE_EXCEEDED' });
});
