import Anthropic from "@anthropic-ai/sdk";
import { VideoMetadata } from "../types/response";

const SYSTEM_PROMPT = `You are a culinary AI assistant that extracts structured recipe data from social media video metadata.
You receive video titles, descriptions/captions, and sometimes a thumbnail image.
Extract all recipe information into precise JSON. Rules:
- Be literal with measurements — never invent quantities not mentioned in the source
- If a field is unclear or missing, use null rather than guessing
- Combine duplicate ingredients (e.g. "2 cloves garlic" mentioned twice → list once)
- Steps should be complete sentences, one action per step
- Difficulty: "easy" (< 30 min, few ingredients), "medium" (30–60 min), "hard" (> 60 min or complex techniques)
- Respond ONLY with a valid JSON object wrapped in \`\`\`json ... \`\`\` — no other text`;

const RECIPE_SCHEMA = `{
  "title": "string — clean recipe name, not the creator's name or channel",
  "cook_time_minutes": "integer | null",
  "prep_time_minutes": "integer | null",
  "servings": "integer | null",
  "difficulty": "\\"easy\\" | \\"medium\\" | \\"hard\\" | null",
  "tags": ["string — e.g. \\"salmon\\", \\"dinner\\", \\"30-minute\\""],
  "ingredients": [
    {
      "name": "string",
      "quantity": "string | null — e.g. \\"2\\", \\"1/2\\", \\"a pinch\\"",
      "unit": "string | null — e.g. \\"cups\\", \\"tbsp\\", \\"g\\"",
      "notes": "string | null — e.g. \\"finely chopped\\", \\"room temperature\\""
    }
  ],
  "steps": [
    {
      "step_number": "integer starting at 1",
      "instruction": "string — complete actionable sentence",
      "duration_minutes": "integer | null"
    }
  ],
  "confidence": "float 0.0–1.0 — your confidence in extraction quality"
}`;

export function buildExtractionPrompt(
  metadata: VideoMetadata,
  thumbnailBase64: string | null
): { system: string; messages: Anthropic.MessageParam[] } {
  const captionText =
    metadata.description.trim().length > 0
      ? metadata.description.slice(0, 3000)
      : "(no caption available)";

  const textContent = `Extract the recipe from this social media cooking video.

Platform: ${metadata.platform}
Video Title: ${metadata.title}
Creator: ${metadata.uploader}
${metadata.duration ? `Duration: ${metadata.duration}s` : ""}

Caption/Description:
---
${captionText}
---

Extract into this exact JSON schema:
${RECIPE_SCHEMA}`;

  const userContent: Anthropic.ContentBlockParam[] = [
    { type: "text", text: textContent },
  ];

  if (thumbnailBase64) {
    const base64Data = thumbnailBase64.replace(/^data:image\/\w+;base64,/, "");
    userContent.push({
      type: "image",
      source: {
        type: "base64",
        media_type: "image/jpeg",
        data: base64Data,
      },
    });
    userContent.push({
      type: "text",
      text: "The image above is a thumbnail from the video. Use it to help identify the dish if the caption is sparse.",
    });
  }

  return {
    system: SYSTEM_PROMPT,
    messages: [{ role: "user", content: userContent }],
  };
}
