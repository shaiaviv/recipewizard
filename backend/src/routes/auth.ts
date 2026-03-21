import { Router, Request, Response } from "express";
import { verifyGoogleToken, findOrCreateUser, signJwt } from "../services/userService";

const router = Router();

router.post("/google", async (req: Request, res: Response) => {
  const { idToken } = req.body as { idToken?: string };
  if (!idToken) {
    res.status(400).json({ error: "idToken is required" });
    return;
  }

  let userInfo;
  try {
    userInfo = await verifyGoogleToken(idToken);
  } catch (err) {
    console.error("[auth] Google token verification failed:", err);
    res.status(401).json({ error: "Invalid Google ID token" });
    return;
  }

  const user = await findOrCreateUser(userInfo);
  const token = signJwt(user.id, user.email);

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
