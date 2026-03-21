# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Backend (Node.js/TypeScript)

```bash
cd backend

npm run dev          # Start dev server with hot reload (port 8000)
npm run build        # Compile TypeScript to dist/
npm run typecheck    # Type-check without emitting
```

Test an extraction end-to-end:
```bash
curl -X POST http://localhost:8000/api/v1/extract \
  -H "Content-Type: application/json" \
  -d '{"url": "TIKTOK_OR_INSTAGRAM_URL", "include_thumbnail": false}'
```

### iOS

```bash
open iOS/RecipeWizard.xcodeproj   # Open in Xcode

# Regenerate .xcodeproj after editing project.yml (requires xcodegen):
cd iOS && /tmp/xcodegen/xcodegen/bin/xcodegen generate --spec project.yml
```

There are no unit tests yet. Manual testing requires a physical device — the Share Extension and App Groups don't work in the simulator.

---

## Architecture

### Backend (`backend/src/`)

Three-stage pipeline triggered by `POST /api/v1/extract`:

1. **`services/videoExtractor.ts`** — spawns `yt-dlp` via `yt-dlp-wrap` to fetch video metadata (title, description, thumbnail URL, uploader, duration) without downloading the video itself. Passes `cookies.txt` for Instagram auth if `INSTAGRAM_COOKIES_PATH` is set.

2. **`services/imageService.ts`** — downloads the thumbnail and resizes it to max 1024px via `sharp`, returns base64-encoded JPEG for the Claude vision call.

3. **`services/claudeService.ts`** — calls `claude-sonnet-4-6` with a multi-modal prompt (text metadata + thumbnail image). `utils/promptBuilder.ts` assembles the prompt and defines the exact JSON schema Claude must fill. The response is parsed out of a ` ```json ``` ` code block.

The route handler in `routes/recipes.ts` orchestrates these three services. `utils/urlValidator.ts` handles URL normalization, including extracting URLs from TikTok share copy text.

### iOS (`iOS/`)

**Two targets** share code in `iOS/Shared/`:
- **RecipeWizard** (main app) — SwiftUI + SwiftData
- **ShareExtension** — receives URLs from the iOS share sheet

**Data flow for shared recipes:**
The Share Extension cannot access SwiftData directly (memory limit + separate process). Instead it writes `[RecipeResponse]` as JSON into `UserDefaults(suiteName: appGroupID)["pendingRecipes"]`. The main app drains this queue in `RecipeListView` on every foreground event and inserts into SwiftData.

**SwiftData + CloudKit constraint:** All `@Model` properties are optional or have defaults, and `[String]` arrays are stored as `Data` (JSON-encoded) because CloudKit doesn't support native arrays. CloudKit sync is currently disabled — to enable it, change `ModelConfiguration` in `RecipeWizardApp.swift` and uncomment the entitlements.

**Key shared files:**
- `Shared/SharedConstants.swift` — App Group ID and backend URL. **Both must match** between the two targets or the extension-to-app queue breaks.
- `Shared/SharedModels.swift` — `RecipeResponse` and related `Codable` structs (not SwiftData — used for JSON transport only).
- `Shared/RecipeAPIService.swift` — `actor` HTTP client with 90s timeout, used by both the main app and the extension.

**`iOS/project.yml`** is the xcodegen spec. Edit this to add files/capabilities/targets, then regenerate the `.xcodeproj`.

### Docker / Railway

In `Dockerfile` CMD, never use `npx <package>` for locally installed packages — use `node_modules/.bin/<package>` directly. `npx` in npm 11 can download the latest version from the registry instead of using the local installation, which caused `npx prisma` to pull Prisma v7 instead of the pinned v5, crashing the container.

### Environment

`backend/.env` (gitignored, copy from `.env.example`):
- `ANTHROPIC_API_KEY` — required
- `INSTAGRAM_COOKIES_PATH` — optional, path to `cookies.txt` for Instagram Reels
- `PORT` — defaults to 8000
