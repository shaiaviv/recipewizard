import { GoogleGenAI } from "@google/genai";

const MODEL = "gemini-3.1-flash-image-preview";

const STYLE_SUFFIX =
  "Studio Ghibli / Hayao Miyazaki anime art style. Soft watercolor textures, " +
  "warm golden light, lush natural colors, cozy and inviting atmosphere, " +
  "detailed food illustration, hand-painted aesthetic, vibrant and appetizing. " +
  "No text, no people, food only.";

export async function generateRecipeImage(
  recipeTitle: string
): Promise<string | null> {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.warn("[imageGenerationService] GEMINI_API_KEY not set — skipping image generation");
    return null;
  }

  const ai = new GoogleGenAI({ apiKey });
  const prompt = `A beautifully illustrated dish of "${recipeTitle}". ${STYLE_SUFFIX}`;

  try {
    const response = await ai.models.generateContent({
      model: MODEL,
      contents: prompt,
      config: {
        responseModalities: ["TEXT", "IMAGE"],
        imageConfig: {
          aspectRatio: "1:1",
          imageSize: "1K",
        },
      },
    });

    for (const part of response.candidates?.[0]?.content?.parts ?? []) {
      if (part.inlineData?.data) {
        const mime = part.inlineData.mimeType ?? "image/png";
        return `data:${mime};base64,${part.inlineData.data}`;
      }
    }

    console.warn("[imageGenerationService] No image part in response");
    return null;
  } catch (err) {
    console.warn("[imageGenerationService] Image generation failed:", err);
    return null;
  }
}
