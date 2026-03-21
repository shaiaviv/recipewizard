const TIKTOK_PATTERNS = [
  /https?:\/\/(www\.)?tiktok\.com\/@[\w.]+\/video\/\d+/,
  /https?:\/\/vm\.tiktok\.com\/\w+/,
  /https?:\/\/vt\.tiktok\.com\/\w+/,
];

const INSTAGRAM_PATTERNS = [
  /https?:\/\/(www\.)?instagram\.com\/(reel|p|tv)\/[\w-]+/,
];

export function isSupportedUrl(url: string): boolean {
  return (
    TIKTOK_PATTERNS.some((p) => p.test(url)) ||
    INSTAGRAM_PATTERNS.some((p) => p.test(url))
  );
}

export function detectPlatform(url: string): "tiktok" | "instagram" | "unknown" {
  if (TIKTOK_PATTERNS.some((p) => p.test(url))) return "tiktok";
  if (INSTAGRAM_PATTERNS.some((p) => p.test(url))) return "instagram";
  return "unknown";
}

/** Extract a URL from text that may contain surrounding copy (e.g. TikTok share text) */
export function extractUrlFromText(text: string): string | null {
  const match = text.match(/https?:\/\/[^\s]+/);
  return match ? match[0] : null;
}
