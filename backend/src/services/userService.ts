import { OAuth2Client } from "google-auth-library";
import jwt from "jsonwebtoken";
import { prisma } from "../lib/prisma";
import type { AuthPayload } from "../middleware/auth";

const googleClient = new OAuth2Client();

export interface GoogleUserInfo {
  googleId: string;
  email: string;
  name: string;
  avatarUrl: string | null;
}

export async function verifyGoogleToken(idToken: string): Promise<GoogleUserInfo> {
  const audiences = [
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_IOS_CLIENT_ID,
  ].filter(Boolean) as string[];

  const ticket = await googleClient.verifyIdToken({
    idToken,
    audience: audiences,
  });
  const payload = ticket.getPayload();
  if (!payload?.sub || !payload.email) {
    throw new Error("Invalid Google ID token: missing sub or email");
  }
  return {
    googleId: payload.sub,
    email: payload.email,
    name: payload.name ?? payload.email,
    avatarUrl: payload.picture ?? null,
  };
}

export async function findOrCreateUser(info: GoogleUserInfo) {
  return prisma.user.upsert({
    where: { googleId: info.googleId },
    update: {
      email: info.email,
      name: info.name,
      avatarUrl: info.avatarUrl,
    },
    create: {
      googleId: info.googleId,
      email: info.email,
      name: info.name,
      avatarUrl: info.avatarUrl,
    },
  });
}

export function signJwt(userId: string, email: string): string {
  const payload: AuthPayload = { userId, email };
  return jwt.sign(payload, process.env.JWT_SECRET!, {
    expiresIn: (process.env.JWT_EXPIRES_IN ?? "30d") as jwt.SignOptions["expiresIn"],
  });
}
