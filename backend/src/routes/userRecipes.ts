import { Router, Request, Response } from "express";
import { requireAuth } from "../middleware/auth";
import { getRecipesForUser, deleteRecipeForUser } from "../services/recipeService";

const router = Router();

router.use(requireAuth);

router.get("/", async (req: Request, res: Response) => {
  const recipes = await getRecipesForUser(req.user!.userId);
  res.json(recipes.map((r) => ({
    id: r.id,
    title: r.title,
    platform: r.platform,
    source_url: r.sourceUrl,
    thumbnail_url: r.thumbnailUrl ?? null,
    thumbnail_base64: r.thumbnailBase64 ?? null,
    description: r.description ?? null,
    cook_time_minutes: r.cookTimeMinutes ?? null,
    prep_time_minutes: r.prepTimeMinutes ?? null,
    servings: r.servings ?? null,
    difficulty: r.difficulty ?? null,
    tags: r.tags ?? [],
    extraction_confidence: r.extractionConfidence,
    raw_caption: r.rawCaption ?? null,
    ingredients: r.ingredients.map((ing) => ({
      name: ing.name,
      quantity: ing.quantity ?? null,
      unit: ing.unit ?? null,
      notes: ing.notes ?? null,
    })),
    steps: r.steps.map((step) => ({
      step_number: step.stepNumber,
      instruction: step.instruction,
      duration_minutes: step.durationMinutes ?? null,
    })),
  })));
});

router.delete("/:id", async (req: Request, res: Response) => {
  const deleted = await deleteRecipeForUser(String(req.params.id), req.user!.userId);
  if (!deleted) {
    res.status(404).json({ error: "Recipe not found" });
    return;
  }
  res.status(204).send();
});

export default router;
