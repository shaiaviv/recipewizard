import { Router } from "express";
import fs from "fs";
import path from "path";
import { prisma } from "../lib/prisma";

const router = Router();

router.get("/health", async (_req, res) => {
  const cookiesPath = process.env.INSTAGRAM_COOKIES_PATH;
  let cookiesStatus: "ok" | "missing" | "stale" | "not_configured" = "not_configured";

  if (cookiesPath) {
    const resolved = path.resolve(cookiesPath);
    if (fs.existsSync(resolved)) {
      const stat = fs.statSync(resolved);
      const ageMs = Date.now() - stat.mtimeMs;
      const ageDays = ageMs / (1000 * 60 * 60 * 24);
      cookiesStatus = ageDays > 30 ? "stale" : "ok";
    } else {
      cookiesStatus = "missing";
    }
  }

  let dbStatus: "ok" | "error" = "ok";
  let dbError: string | undefined;
  try {
    await prisma.$queryRaw`SELECT 1`;
  } catch (err) {
    dbStatus = "error";
    dbError = err instanceof Error ? err.message : String(err);
  }

  res.json({
    status: dbStatus === "ok" ? "ok" : "degraded",
    timestamp: new Date().toISOString(),
    instagram_cookies: cookiesStatus,
    database: dbStatus,
    ...(dbError && { database_error: dbError }),
    ...(cookiesStatus === "stale" && {
      warning:
        "Instagram cookies are older than 30 days. Re-export from your browser to restore Instagram support.",
    }),
  });
});

export default router;
