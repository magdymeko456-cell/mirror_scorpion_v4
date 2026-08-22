const { onCall } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const { initializeApp } = require("firebase-admin/app");

const { buildHealthResponse } = require("./src/health");

// تعتمد Cloud Functions على هوية بيئة التشغيل الافتراضية.
// لا تُضف serviceAccountKey.json أو أي مفتاح خاص إلى المشروع.
initializeApp();

exports.healthCheck = onCall({ region: "us-central1" }, (request) => {
  const response = buildHealthResponse({
    activeProjectId: process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT,
    authenticated: request.auth != null,
  });

  logger.info("Mirror Scorpion healthCheck completed", {
    activeProjectId: response.activeProjectId,
    authenticated: response.authenticated,
  });

  return response;
});
