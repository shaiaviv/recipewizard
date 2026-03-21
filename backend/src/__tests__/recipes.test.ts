import { describe, it, expect, vi, beforeEach } from "vitest";
import request from "supertest";

// Mock all external services before importing the app
vi.mock("../services/videoExtractor", () => ({
  extractVideoMetadata: vi.fn(),
}));
vi.mock("../services/claudeService", () => ({
  extractRecipeFromVideo: vi.fn(),
  parseClaudeResponse: vi.fn(),
}));
vi.mock("../services/imageService", () => ({
  downloadAndEncodeImage: vi.fn(),
}));

import { app } from "../index";
import { extractVideoMetadata } from "../services/videoExtractor";
import { extractRecipeFromVideo } from "../services/claudeService";
import { downloadAndEncodeImage } from "../services/imageService";

const mockMetadata = {
  title: "Garlic Butter Pasta",
  description: "A quick and delicious pasta recipe.",
  thumbnail_url: "https://example.com/thumb.jpg",
  uploader: "Chef John",
  duration: 60,
  platform: "tiktok",
  webpage_url: "https://www.tiktok.com/@chef.john/video/1234567890",
};

const mockRecipeData = {
  title: "Garlic Butter Pasta",
  description: "A quick and delicious pasta recipe.",
  cook_time_minutes: 20,
  prep_time_minutes: 10,
  servings: 2,
  difficulty: "easy" as const,
  tags: ["pasta", "quick"],
  ingredients: [{ name: "pasta", quantity: "200", unit: "g", notes: null }],
  steps: [{ step_number: 1, instruction: "Cook pasta.", duration_minutes: 10 }],
  extraction_confidence: 0.9,
};

beforeEach(() => {
  vi.clearAllMocks();
});

describe("POST /api/v1/extract", () => {
  it("returns 400 when url is missing", async () => {
    const res = await request(app).post("/api/v1/extract").send({});
    expect(res.status).toBe(400);
    expect(res.body.error).toBe("url is required");
  });

  it("returns 422 when url is not from TikTok or Instagram", async () => {
    const res = await request(app)
      .post("/api/v1/extract")
      .send({ url: "https://youtube.com/watch?v=abc" });
    expect(res.status).toBe(422);
    expect(res.body.error).toMatch(/TikTok or Instagram/);
  });

  it("returns 422 when share text contains no URL", async () => {
    const res = await request(app)
      .post("/api/v1/extract")
      .send({ url: "just some text with no link" });
    expect(res.status).toBe(422);
    expect(res.body.error).toMatch(/Could not find a URL/);
  });

  it("extracts URL from TikTok share text and succeeds", async () => {
    vi.mocked(extractVideoMetadata).mockResolvedValue(mockMetadata);
    vi.mocked(downloadAndEncodeImage).mockResolvedValue(null);
    vi.mocked(extractRecipeFromVideo).mockResolvedValue(mockRecipeData);

    const shareText =
      "Check this out! https://www.tiktok.com/@chef.john/video/1234567890 via TikTok";
    const res = await request(app)
      .post("/api/v1/extract")
      .send({ url: shareText });

    expect(res.status).toBe(200);
    expect(res.body.title).toBe("Garlic Butter Pasta");
    expect(res.body.platform).toBe("tiktok");
  });

  it("returns 200 with full recipe for a valid TikTok URL", async () => {
    vi.mocked(extractVideoMetadata).mockResolvedValue(mockMetadata);
    vi.mocked(downloadAndEncodeImage).mockResolvedValue(
      "base64encodedimage=="
    );
    vi.mocked(extractRecipeFromVideo).mockResolvedValue(mockRecipeData);

    const res = await request(app).post("/api/v1/extract").send({
      url: "https://www.tiktok.com/@chef.john/video/1234567890",
    });

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      title: "Garlic Butter Pasta",
      platform: "tiktok",
      source_url: "https://www.tiktok.com/@chef.john/video/1234567890",
      extraction_confidence: 0.9,
    });
    expect(res.body.ingredients).toHaveLength(1);
    expect(res.body.steps).toHaveLength(1);
  });

  it("returns 502 when video metadata extraction fails", async () => {
    vi.mocked(extractVideoMetadata).mockRejectedValue(
      new Error("yt-dlp failed")
    );

    const res = await request(app).post("/api/v1/extract").send({
      url: "https://www.tiktok.com/@chef.john/video/1234567890",
    });

    expect(res.status).toBe(502);
    expect(res.body.error).toBe("Failed to fetch video metadata");
    expect(res.body.detail).toBe("yt-dlp failed");
  });

  it("returns 500 when Claude extraction fails", async () => {
    vi.mocked(extractVideoMetadata).mockResolvedValue(mockMetadata);
    vi.mocked(downloadAndEncodeImage).mockResolvedValue(null);
    vi.mocked(extractRecipeFromVideo).mockRejectedValue(
      new Error("Claude API error")
    );

    const res = await request(app).post("/api/v1/extract").send({
      url: "https://www.tiktok.com/@chef.john/video/1234567890",
    });

    expect(res.status).toBe(500);
    expect(res.body.error).toBe("AI recipe extraction failed");
    expect(res.body.detail).toBe("Claude API error");
  });

  it("skips thumbnail download when include_thumbnail is false", async () => {
    vi.mocked(extractVideoMetadata).mockResolvedValue(mockMetadata);
    vi.mocked(extractRecipeFromVideo).mockResolvedValue(mockRecipeData);

    const res = await request(app).post("/api/v1/extract").send({
      url: "https://www.tiktok.com/@chef.john/video/1234567890",
      include_thumbnail: false,
    });

    expect(res.status).toBe(200);
    expect(downloadAndEncodeImage).not.toHaveBeenCalled();
    expect(res.body.thumbnail_base64).toBeNull();
  });
});
