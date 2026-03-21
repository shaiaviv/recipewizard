import "dotenv/config";
import express from "express";
import cors from "cors";
import rateLimit, { ipKeyGenerator } from "express-rate-limit";
import healthRouter from "./routes/health";
import recipesRouter from "./routes/recipes";
import authRouter from "./routes/auth";
import userRecipesRouter from "./routes/userRecipes";

export const app = express();
const PORT = parseInt(process.env.PORT ?? "8000", 10);

// Middleware
app.use(cors());
app.use(express.json({ limit: "10mb" }));

// Request logging
app.use((req, _res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// Rate limiting — 60 requests/min per user (applied to all /api/v1 routes)
app.use(
  "/api/v1",
  rateLimit({
    windowMs: 60 * 1000,
    max: 60,
    keyGenerator: (req) => req.user?.userId ?? ipKeyGenerator(req.ip ?? "anonymous"),
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: "Too many requests, please slow down" },
  })
);

// Routes
app.use("/", healthRouter);
app.use("/api/v1/auth", authRouter);           // public
app.use("/api/v1", recipesRouter);             // requireAuth applied per-route inside
app.use("/api/v1/recipes", userRecipesRouter); // requireAuth applied inside

// Start
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`RecipeWizard backend running on http://localhost:${PORT}`);
    console.log(`  POST http://localhost:${PORT}/api/v1/extract`);
    console.log(`  GET  http://localhost:${PORT}/health`);

    if (!process.env.ANTHROPIC_API_KEY) {
      console.warn("⚠️  ANTHROPIC_API_KEY is not set — recipe extraction will fail");
    }
    if (!process.env.GOOGLE_CLIENT_ID) {
      console.warn("⚠️  GOOGLE_CLIENT_ID is not set — auth will fail");
    }
    if (!process.env.JWT_SECRET) {
      console.warn("⚠️  JWT_SECRET is not set — auth will fail");
    }
  });
}
