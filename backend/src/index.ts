import "dotenv/config";
import express from "express";
import cors from "cors";
import healthRouter from "./routes/health";
import recipesRouter from "./routes/recipes";

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

// Routes
app.use("/", healthRouter);
app.use("/api/v1", recipesRouter);

// Start
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`RecipeWizard backend running on http://localhost:${PORT}`);
    console.log(`  POST http://localhost:${PORT}/api/v1/extract`);
    console.log(`  GET  http://localhost:${PORT}/health`);

    if (!process.env.ANTHROPIC_API_KEY) {
      console.warn("⚠️  ANTHROPIC_API_KEY is not set — recipe extraction will fail");
    }
  });
}
