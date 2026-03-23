import Anthropic from "@anthropic-ai/sdk";
import { buildExtractionPrompt } from "../utils/promptBuilder";
import { VideoMetadata, RecipeResponse, Ingredient, RecipeStep } from "../types/response";

const client = new Anthropic();

export class NotARecipeError extends Error {
  constructor() {
    super("This video does not appear to be a recipe or cooking video");
    this.name = "NotARecipeError";
  }
}

interface RawExtraction {
  title?: string;
  cook_time_minutes?: number | null;
  prep_time_minutes?: number | null;
  servings?: number | null;
  difficulty?: string | null;
  tags?: string[];
  ingredients?: Partial<Ingredient>[];
  steps?: Partial<RecipeStep>[];
  confidence?: number;
}

export function parseClaudeResponse(text: string): RawExtraction {
  const match = text.match(/```json\s*([\s\S]*?)```/);
  if (!match) {
    try {
      return JSON.parse(text);
    } catch {
      throw new Error("Claude response did not contain valid JSON");
    }
  }
  return JSON.parse(match[1]);
}

async function isRecipeVideo(metadata: VideoMetadata): Promise<boolean> {
  const prompt = `Video title: ${metadata.title}
Creator: ${metadata.uploader}
Caption (first 500 chars): ${metadata.description.slice(0, 500) || "(none)"}

Does this video teach the viewer how to cook or make a recipe at home?
Reply with only YES or NO.`;

  const response = await client.messages.create({
    model: "claude-haiku-4-5-20251001",
    max_tokens: 5,
    system: "You classify social media videos. Reply with only YES or NO.",
    messages: [{ role: "user", content: prompt }],
  });

  const answer = response.content[0].type === "text"
    ? response.content[0].text.trim().toUpperCase()
    : "NO";

  console.log("[claude] isRecipeVideo answer:", answer);
  return answer.startsWith("YES");
}

export async function extractRecipeFromVideo(
  metadata: VideoMetadata,
  thumbnailBase64: string | null
): Promise<Omit<RecipeResponse, "source_url" | "platform" | "thumbnail_url" | "thumbnail_base64" | "raw_caption">> {
  // Fast, cheap pre-check before running the full extraction
  const isRecipe = await isRecipeVideo(metadata);
  if (!isRecipe) {
    throw new NotARecipeError();
  }

  const { system, messages } = buildExtractionPrompt(metadata, thumbnailBase64);

  const response = await client.messages.create({
    model: "claude-sonnet-4-6",
    max_tokens: 4096,
    system,
    messages,
  });

  const rawText =
    response.content[0].type === "text" ? response.content[0].text : "";

  let extracted: RawExtraction;
  try {
    extracted = parseClaudeResponse(rawText);
  } catch (err) {
    throw new Error(`Failed to parse Claude response: ${err}`);
  }

  const ingredients: Ingredient[] = (extracted.ingredients ?? []).map((ing) => ({
    name: ing.name ?? "Unknown ingredient",
    quantity: ing.quantity ?? null,
    unit: ing.unit ?? null,
    notes: ing.notes ?? null,
  }));

  const steps: RecipeStep[] = (extracted.steps ?? []).map((step, i) => ({
    step_number: step.step_number ?? i + 1,
    instruction: step.instruction ?? "",
    duration_minutes: step.duration_minutes ?? null,
  }));

  const confidence = typeof extracted.confidence === "number"
    ? Math.max(0, Math.min(1, extracted.confidence))
    : 0.5;

  return {
    title: extracted.title ?? metadata.title ?? "Untitled Recipe",
    description: metadata.description.slice(0, 500) || null,
    cook_time_minutes: extracted.cook_time_minutes ?? null,
    prep_time_minutes: extracted.prep_time_minutes ?? null,
    servings: extracted.servings ?? null,
    difficulty: (extracted.difficulty as RecipeResponse["difficulty"]) ?? null,
    tags: extracted.tags ?? [],
    ingredients,
    steps,
    extraction_confidence: confidence,
  };
}
