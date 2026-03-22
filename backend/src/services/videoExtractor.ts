import YTDlpWrap from "yt-dlp-wrap";
import path from "path";
import fs from "fs";
import os from "os";
import { VideoMetadata } from "../types/response";

const ytDlp = new YTDlpWrap();

// Decode INSTAGRAM_COOKIES_B64 to a temp file once at startup
let resolvedCookiesPath: string | null = null;

const cookiesB64 = process.env.INSTAGRAM_COOKIES_B64;
const cookiesPath = process.env.INSTAGRAM_COOKIES_PATH;

if (cookiesB64) {
  const tmpPath = path.join(os.tmpdir(), "instagram_cookies.txt");
  fs.writeFileSync(tmpPath, Buffer.from(cookiesB64, "base64"));
  resolvedCookiesPath = tmpPath;
} else if (cookiesPath) {
  resolvedCookiesPath = path.resolve(cookiesPath);
}

function buildArgs(url: string): string[] {
  const args = ["--dump-json", "--no-playlist", "--no-warnings", url];

  if (resolvedCookiesPath) {
    args.unshift("--cookies", resolvedCookiesPath);
  }

  return args;
}

export async function extractVideoMetadata(url: string): Promise<VideoMetadata> {
  const args = buildArgs(url);

  let rawJson: string;
  try {
    rawJson = await ytDlp.execPromise(args);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    throw new Error(`yt-dlp extraction failed: ${message}`);
  }

  let info: Record<string, unknown>;
  try {
    info = JSON.parse(rawJson);
  } catch {
    throw new Error("yt-dlp returned unparseable output");
  }

  const extractorKey = String(info["extractor_key"] ?? "").toLowerCase();
  const platform = extractorKey.includes("tiktok")
    ? "tiktok"
    : extractorKey.includes("instagram")
      ? "instagram"
      : extractorKey || "unknown";

  // Pick the best thumbnail URL (prefer a mid-resolution one)
  let thumbnailUrl: string | null = null;
  const thumbnails = info["thumbnails"] as Array<{ url?: string; width?: number }> | undefined;
  if (thumbnails && thumbnails.length > 0) {
    const mid = thumbnails.find((t) => t.width && t.width <= 1280) ?? thumbnails[thumbnails.length - 1];
    thumbnailUrl = mid.url ?? null;
  } else if (info["thumbnail"]) {
    thumbnailUrl = String(info["thumbnail"]);
  }

  return {
    title: String(info["title"] ?? ""),
    description: String(info["description"] ?? ""),
    thumbnail_url: thumbnailUrl,
    uploader: String(info["uploader"] ?? info["channel"] ?? ""),
    duration: typeof info["duration"] === "number" ? info["duration"] : null,
    platform,
    webpage_url: String(info["webpage_url"] ?? url),
  };
}
