import { Router } from "express";
import fs from "fs";
import path from "path";

const router = Router();

router.get("/health", (_req, res) => {
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

  res.json({
    status: "ok",
    timestamp: new Date().toISOString(),
    instagram_cookies: cookiesStatus,
    ...(cookiesStatus === "stale" && {
      warning:
        "Instagram cookies are older than 30 days. Re-export from your browser to restore Instagram support.",
    }),
  });
});

export default router;
