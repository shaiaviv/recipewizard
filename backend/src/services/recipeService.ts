import { prisma } from "../lib/prisma";
import type { RecipeResponse } from "../types/response";

export async function saveRecipeForUser(
  userId: string,
  recipe: RecipeResponse
): Promise<{ id: string }> {
  return prisma.recipe.create({
    data: {
      userId,
      title: recipe.title,
      platform: recipe.platform,
      sourceUrl: recipe.source_url,
      thumbnailUrl: recipe.thumbnail_url ?? null,
      thumbnailBase64: recipe.thumbnail_base64 ?? null,
      description: recipe.description ?? null,
      cookTimeMinutes: recipe.cook_time_minutes ?? null,
      prepTimeMinutes: recipe.prep_time_minutes ?? null,
      servings: recipe.servings ?? null,
      difficulty: recipe.difficulty ?? null,
      tags: recipe.tags,
      extractionConfidence: recipe.extraction_confidence,
      rawCaption: recipe.raw_caption ?? null,
      ingredients: {
        create: recipe.ingredients.map((ing, i) => ({
          name: ing.name,
          quantity: ing.quantity ?? null,
          unit: ing.unit ?? null,
          notes: ing.notes ?? null,
          sortOrder: i,
        })),
      },
      steps: {
        create: recipe.steps.map((step) => ({
          stepNumber: step.step_number,
          instruction: step.instruction,
          durationMinutes: step.duration_minutes ?? null,
        })),
      },
    },
    select: { id: true },
  });
}

export async function getRecipesForUser(userId: string) {
  return prisma.recipe.findMany({
    where: { userId },
    include: {
      ingredients: { orderBy: { sortOrder: "asc" } },
      steps: { orderBy: { stepNumber: "asc" } },
    },
    orderBy: { createdAt: "desc" },
  });
}

export async function deleteRecipeForUser(
  recipeId: string,
  userId: string
): Promise<boolean> {
  const recipe = await prisma.recipe.findFirst({
    where: { id: recipeId, userId },
    select: { id: true },
  });
  if (!recipe) return false;
  await prisma.recipe.delete({ where: { id: recipeId } });
  return true;
}
