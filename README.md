# RecipeWizard

A personal iOS app for saving recipes from TikTok and Instagram Reels. Share a video to the app and AI automatically extracts the recipe — ingredients, steps, cook time, and more — and saves it to your recipe book.

Inspired by [Honeydew](https://honeydewcook.com/).

---

## How it works

1. Open a TikTok or Instagram Reel
2. Tap **Share** → select **RecipeWizard** from the share sheet
3. The app sends the URL to the backend, which fetches the video metadata using yt-dlp
4. Claude AI extracts a structured recipe from the caption + thumbnail
5. The recipe appears in your recipe book

---

## Repository structure

```
recipewizard/
├── iOS/              # iOS app (SwiftUI + SwiftData)
│   ├── RecipeWizard.xcodeproj
│   ├── RecipeWizard/         # Main app target
│   ├── ShareExtension/       # iOS Share Extension
│   └── Shared/               # Code shared between both targets
├── backend/          # Node.js/TypeScript backend
│   └── src/
└── docs/             # Setup guides
```

---

## Quick start

### 1. Backend

**Prerequisites:** Node.js 20+, yt-dlp installed globally, an Anthropic API key.

```bash
# Install yt-dlp
brew install yt-dlp          # macOS
# or: pip install yt-dlp

# Set up backend
cd backend
npm install
cp .env.example .env
# Edit .env — add your ANTHROPIC_API_KEY
npm run dev
# Backend runs on http://localhost:8000
```

Test it:
```bash
curl -X POST http://localhost:8000/api/v1/extract \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.tiktok.com/@gordonramsay/video/...", "include_thumbnail": true}'
```

### 2. iOS app

**Prerequisites:** Xcode 15+, a device running iOS 17+ (simulator cannot test the Share Extension or CloudKit).

```bash
open iOS/RecipeWizard.xcodeproj
```

In Xcode:
1. Select the **RecipeWizard** target → **Signing & Capabilities** tab
2. Set your **Team** (free personal team works for USB device testing)
3. Change the **Bundle Identifier** to something unique (e.g. `com.yourname.recipewizard`)
4. Do the same for the **ShareExtension** target, using `com.yourname.recipewizard.ShareExtension`
5. Add the **App Groups** capability to **both** targets and use the same group ID (e.g. `group.com.yourname.recipewizard`)
6. In `iOS/Shared/SharedConstants.swift`, update `appGroupID` and `backendURL` to match

See [docs/SETUP.md](docs/SETUP.md) for a complete step-by-step walkthrough.

---

## Syncing with your partner

Currently recipes are stored locally on each device (SwiftData without CloudKit). Syncing between two phones requires an [Apple Developer Program](https://developer.apple.com/programs/) membership ($99/year).

Once you have a paid account, see [docs/CLOUDKIT.md](docs/CLOUDKIT.md) to enable two-device sync.

---

## Deploying the backend

For always-on use (so the Share Extension works when you're not on your Mac), deploy to Railway:

```bash
npm install -g @railway/cli
railway login
cd backend
railway init
railway up
# Set ANTHROPIC_API_KEY in the Railway dashboard
```

Then update `SharedConstants.backendURL` in the iOS app to your Railway URL.

---

## Tech stack

| Layer | Tech |
|-------|------|
| iOS app | SwiftUI, SwiftData, iOS 17+ |
| Share Extension | UIKit + SwiftUI |
| Backend | Node.js 20, TypeScript, Express |
| Video extraction | yt-dlp |
| AI | Claude claude-sonnet-4-6 (Anthropic) |
| Sync (future) | CloudKit |
