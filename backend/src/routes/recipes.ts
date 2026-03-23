import { Router, Request, Response } from "express";
import { ExtractRequest } from "../types/request";
import { extractVideoMetadata } from "../services/videoExtractor";
import { extractRecipeFromVideo, NotARecipeError } from "../services/claudeService";
import { downloadAndEncodeImage } from "../services/imageService";
import { generateRecipeImage } from "../services/imageGenerationService";
import { isSupportedUrl, extractUrlFromText } from "../utils/urlValidator";
import { requireAuth } from "../middleware/auth";
import { saveRecipeForUser } from "../services/recipeService";

const router = Router();

router.post("/extract", requireAuth, async (req: Request, res: Response) => {
  const body = req.body as ExtractRequest;
  let url = body.url?.trim();

  if (!url) {
    res.status(400).json({ error: "url is required" });
    return;
  }

  // Handle TikTok share text that embeds URL in surrounding copy
  if (!url.startsWith("http")) {
    const extracted = extractUrlFromText(url);
    if (!extracted) {
      res.status(422).json({ error: "Could not find a URL in the provided text" });
      return;
    }
    url = extracted;
  }

  if (!isSupportedUrl(url)) {
    res.status(422).json({
      error: "URL must be from TikTok or Instagram",
      supported: [
        "https://www.tiktok.com/@user/video/...",
        "https://vm.tiktok.com/...",
        "https://www.instagram.com/reel/...",
        "https://www.instagram.com/p/...",
      ],
    });
    return;
  }

  // Step 1: Extract video metadata via yt-dlp
  let metadata;
  try {
    metadata = await extractVideoMetadata(url);
  } catch (err) {
    console.error("[recipes] Video extraction failed:", err);
    res.status(502).json({
      error: "Failed to fetch video metadata",
      detail: err instanceof Error ? err.message : String(err),
    });
    return;
  }

  // Step 2: Download + encode thumbnail (optional)
  let thumbnailBase64: string | null = null;
  if (body.include_thumbnail !== false && metadata.thumbnail_url) {
    thumbnailBase64 = await downloadAndEncodeImage(metadata.thumbnail_url);
  }

  // Step 3: Extract recipe with Claude AI
  let recipeData;
  try {
    recipeData = await extractRecipeFromVideo(metadata, thumbnailBase64);
  } catch (err) {
    if (err instanceof NotARecipeError) {
      res.status(422).json({ error: err.message });
      return;
    }
    console.error("[recipes] Claude extraction failed:", err);
    res.status(500).json({
      error: "AI recipe extraction failed",
      detail: err instanceof Error ? err.message : String(err),
    });
    return;
  }

  // Step 4: Generate Miyazaki-style illustration using the extracted recipe title
  const generatedImage = await generateRecipeImage(recipeData.title);

  const responsePayload = {
    ...recipeData,
    source_url: url,
    platform: metadata.platform,
    thumbnail_url: metadata.thumbnail_url,
    thumbnail_base64: generatedImage ?? thumbnailBase64,
    raw_caption: metadata.description.slice(0, 1000) || null,
  };

  // Save to DB for the authenticated user (non-blocking)
  saveRecipeForUser(req.user!.userId, responsePayload).catch((err) => {
    console.error("[recipes] Failed to save recipe to DB:", err);
  });

  res.json(responsePayload);
});

export default router;
