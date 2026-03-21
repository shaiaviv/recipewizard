import { Router, Request, Response } from "express";
import { requireAuth } from "../middleware/auth";
import { getRecipesForUser, deleteRecipeForUser } from "../services/recipeService";

const router = Router();

router.use(requireAuth);

router.get("/", async (req: Request, res: Response) => {
  const recipes = await getRecipesForUser(req.user!.userId);
  res.json(recipes);
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
