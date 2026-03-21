# Backend API Reference

Base URL (development): `http://localhost:8000`

---

## GET /health

Returns backend status and checks Instagram cookies freshness.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-03-21T10:00:00.000Z",
  "instagram_cookies": "ok" | "stale" | "missing" | "not_configured",
  "warning": "..." // only present when cookies are stale
}
```

---

## POST /api/v1/extract

Extracts a recipe from a TikTok or Instagram URL.

**Request body:**
```json
{
  "url": "https://www.tiktok.com/@user/video/123456789",
  "include_thumbnail": true
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `url` | string | ✅ | TikTok or Instagram URL. Also accepts plain text containing a URL (handles TikTok share copy). |
| `include_thumbnail` | boolean | ❌ | Whether to download and return the thumbnail as base64. Default: `true`. Set to `false` to reduce response size. |

**Success response (200):**
```json
{
  "title": "Crispy Garlic Butter Salmon",
  "platform": "tiktok",
  "source_url": "https://www.tiktok.com/@user/video/123456789",
  "thumbnail_url": "https://...",
  "thumbnail_base64": "data:image/jpeg;base64,...",
  "description": "The best salmon recipe...",
  "cook_time_minutes": 20,
  "prep_time_minutes": 10,
  "servings": 2,
  "difficulty": "easy",
  "tags": ["salmon", "dinner", "30-minute"],
  "ingredients": [
    {
      "name": "salmon fillet",
      "quantity": "2",
      "unit": "pieces",
      "notes": "skin-on"
    }
  ],
  "steps": [
    {
      "step_number": 1,
      "instruction": "Pat salmon dry with paper towels.",
      "duration_minutes": null
    }
  ],
  "extraction_confidence": 0.92,
  "raw_caption": "..."
}
```

**Error responses:**

| Status | Meaning |
|--------|---------|
| `400` | Missing `url` field |
| `422` | URL is not from TikTok or Instagram |
| `500` | Claude AI extraction failed |
| `502` | yt-dlp failed to fetch video (private/deleted video, or expired Instagram cookies) |

---

## Supported URL formats

**TikTok:**
- `https://www.tiktok.com/@username/video/1234567890`
- `https://vm.tiktok.com/ABCDEF/` (short URL)
- `https://vt.tiktok.com/ABCDEF/`
- Plain text containing any of the above (e.g. TikTok app share copy)

**Instagram:**
- `https://www.instagram.com/reel/ABC123/`
- `https://www.instagram.com/p/ABC123/`
- `https://www.instagram.com/tv/ABC123/`
