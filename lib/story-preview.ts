export const STORY_PREVIEW_CHAR_LIMIT = 480;

export function storyPreview(content: string, limit = STORY_PREVIEW_CHAR_LIMIT) {
  const normalized = content.trim();
  if (normalized.length <= limit) return normalized;

  const boundary = normalized.lastIndexOf(" ", limit);
  const safeBoundary = boundary > Math.floor(limit * 0.6) ? boundary : limit;
  return `${normalized.slice(0, safeBoundary).trimEnd()}…`;
}

export function storyNeedsExpansion(content: string, limit = STORY_PREVIEW_CHAR_LIMIT) {
  return content.trim().length > limit;
}
