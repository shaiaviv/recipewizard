import { Router, Request, Response } from "express";
import { verifyGoogleToken, findOrCreateUser, signJwt } from "../services/userService";

const router = Router();

router.post("/google", async (req: Request, res: Response) => {
  const { idToken, displayName } = req.body as { idToken?: string; displayName?: string };
  if (!idToken) {
    res.status(400).json({ error: "idToken is required" });
    return;
  }

  let userInfo;
  try {
    userInfo = await verifyGoogleToken(idToken, displayName);
  } catch (err) {
    console.error("[auth] Google token verification failed:", err);
    res.status(401).json({ error: "Invalid Google ID token" });
    return;
  }

  let user;
  try {
    user = await findOrCreateUser(userInfo);
  } catch (err) {
    console.error("[auth] Database error in findOrCreateUser:", err);
    res.status(500).json({ error: "Database error", detail: err instanceof Error ? err.message : String(err) });
    return;
  }

  let token;
  try {
    token = signJwt(user.id, user.email);
  } catch (err) {
    console.error("[auth] JWT signing failed:", err);
    res.status(500).json({ error: "Token signing failed", detail: err instanceof Error ? err.message : String(err) });
    return;
  }

  res.json({
    token,
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      avatarUrl: user.avatarUrl,
    },
  });
});

export default router;
