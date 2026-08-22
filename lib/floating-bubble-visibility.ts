export function shouldShowInAppTranslationBubble(input: {
  enabled: boolean;
  platform: string;
  hasNativeOverlay: boolean;
}) {
  if (!input.enabled) return false;
  return input.platform !== "android" || !input.hasNativeOverlay;
}
