export interface Ingredient {
  name: string;
  quantity: string | null;
  unit: string | null;
  notes: string | null;
}

export interface RecipeStep {
  step_number: number;
  instruction: string;
  duration_minutes: number | null;
}

export interface RecipeResponse {
  title: string;
  platform: string;
  source_url: string;
  thumbnail_url: string | null;
  thumbnail_base64: string | null;
  description: string | null;
  cook_time_minutes: number | null;
  prep_time_minutes: number | null;
  servings: number | null;
  difficulty: "easy" | "medium" | "hard" | null;
  tags: string[];
  ingredients: Ingredient[];
  steps: RecipeStep[];
  extraction_confidence: number;
  raw_caption: string | null;
}

export interface VideoMetadata {
  title: string;
  description: string;
  thumbnail_url: string | null;
  uploader: string;
  duration: number | null;
  platform: string;
  webpage_url: string;
}
