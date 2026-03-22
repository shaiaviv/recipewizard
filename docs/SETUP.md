# Setup Guide

Complete step-by-step guide to get RecipeWizard running on your iPhone.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Xcode | 15.0+ | App Store or [developer.apple.com](https://developer.apple.com) |
| Node.js | 20+ | `brew install node` |
| yt-dlp | latest | `brew install yt-dlp` |
| Anthropic API key | — | [console.anthropic.com](https://console.anthropic.com) |

---

## Step 1 — Backend

```bash
cd backend
npm install
cp .env.example .env
```

Open `.env` and fill in your `ANTHROPIC_API_KEY`. Everything else can stay as defaults.

Start the dev server:

```bash
npm run dev
# Output: RecipeWizard backend running on http://localhost:8000
```

Verify it works:

```bash
curl http://localhost:8000/health
# Expected: {"status":"ok", ...}
```

---

## Step 2 — iOS App setup in Xcode

1. `open iOS/RecipeWizard.xcodeproj`

2. In the **Project Navigator**, select the **RecipeWizard** project → **RecipeWizard** target → **Signing & Capabilities**:
   - Set **Team** to your Apple ID (free team is fine)
   - Set **Bundle Identifier** to something unique, e.g. `com.yourname.recipewizard`

3. Repeat for the **ShareExtension** target:
   - Bundle ID: `com.yourname.recipewizard.ShareExtension`

4. Add **App Groups** capability to **both** targets:
   - Click `+ Capability` → search "App Groups"
   - Add a group: `group.com.yourname.recipewizard`
   - Make sure the exact same group ID is in both targets

5. Open `iOS/Shared/SharedConstants.swift` and update:
   ```swift
   static let appGroupID = "group.com.yourname.recipewizard"  // match above
   static let backendURL = "http://YOUR-MAC-IP:8000"          // your Mac's local IP
   ```

   Find your Mac's IP: `System Settings → Wi-Fi → Details` (use the local IP, e.g. `192.168.1.x`)

   > **Note:** `localhost` won't work on a device — the phone needs your Mac's actual local IP address.

---

## Step 3 — Run on device

1. Connect your iPhone via USB
2. Trust the computer if prompted on the phone
3. In Xcode, select your iPhone in the scheme picker (top bar)
4. Press **Cmd+R** to build and run

The app will open on your phone. The first launch may prompt you to trust the developer certificate in **Settings → General → VPN & Device Management**.

---

## Step 4 — Test the Share Extension

1. Open TikTok or Instagram on your iPhone
2. Find a cooking video
3. Tap the **Share** button
4. Scroll through the share sheet to find **RecipeWizard** (may be under "More")
5. The extension opens, shows extraction progress, and dismisses automatically
6. Open the RecipeWizard app — your recipe should be there

> **TikTok tip:** TikTok may share a text message with the URL embedded (e.g. "Check out this video! https://vm.tiktok.com/..."). The extension handles this automatically.

---

## Step 5 — Instagram authentication (optional)

Instagram heavily restricts public access. For Instagram Reels, yt-dlp needs your session cookies. You provide these once as the app developer — your users don't need to do anything.

**Export your cookies:**

1. Install the **"Get cookies.txt LOCALLY"** extension in Chrome or Firefox
2. Log into Instagram in that browser
3. Click the extension → **Export cookies for current site**
4. Save the file as `backend/cookies.txt`

**Local dev:**

Set in `backend/.env`:
```
INSTAGRAM_COOKIES_PATH=./cookies.txt
```

**Production (Railway):**

Do this once to set up the Railway CLI:
```bash
npm install -g @railway/cli
railway login
cd backend && railway link   # select your RecipeWizard project
```

Then push your cookies to Railway:
```bash
cd backend
./scripts/update-instagram-cookies.sh
```

This base64-encodes the cookies and sets `INSTAGRAM_COOKIES_B64` on Railway, which the server decodes to a temp file at startup. Railway will redeploy automatically.

**When cookies expire (~90 days):**

1. Re-export cookies from your browser → save as `backend/cookies.txt`
2. Run `./scripts/update-instagram-cookies.sh` again

That's it — one command to refresh.

---

## Backend hot reload

During development, the backend automatically restarts when you save files (powered by `ts-node-dev`):

```bash
cd backend && npm run dev
```

## Changing the backend URL

When moving to production (Railway deployment):
1. Deploy backend: `railway up`
2. Copy the Railway URL (e.g. `https://recipewizard-backend.railway.app`)
3. Update `SharedConstants.backendURL` in the iOS app
4. Rebuild and reinstall the app on your device
