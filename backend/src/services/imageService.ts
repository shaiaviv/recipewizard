import axios from "axios";
import sharp from "sharp";

const MAX_WIDTH = parseInt(process.env.THUMBNAIL_MAX_WIDTH ?? "1024", 10);

export async function downloadAndEncodeImage(
  url: string
): Promise<string | null> {
  try {
    const response = await axios.get(url, {
      responseType: "arraybuffer",
      timeout: 10_000,
      headers: { "User-Agent": "Mozilla/5.0 (compatible; RecipeWizard/1.0)" },
    });

    const buffer = Buffer.from(response.data);
    const resized = await sharp(buffer)
      .resize({ width: MAX_WIDTH, withoutEnlargement: true })
      .jpeg({ quality: 85 })
      .toBuffer();

    return `data:image/jpeg;base64,${resized.toString("base64")}`;
  } catch (err) {
    console.warn("[imageService] Failed to download/encode thumbnail:", err);
    return null;
  }
}
