import { describe, it, expect } from "vitest";
import {
  isSupportedUrl,
  detectPlatform,
  extractUrlFromText,
} from "../utils/urlValidator";

describe("isSupportedUrl", () => {
  it("accepts standard TikTok video URLs", () => {
    expect(
      isSupportedUrl("https://www.tiktok.com/@chef.john/video/1234567890123")
    ).toBe(true);
  });

  it("accepts TikTok URLs without www", () => {
    expect(
      isSupportedUrl("https://tiktok.com/@chef.john/video/1234567890123")
    ).toBe(true);
  });

  it("accepts short TikTok URLs (vm.tiktok.com)", () => {
    expect(isSupportedUrl("https://vm.tiktok.com/ZMabc123/")).toBe(true);
  });

  it("accepts vt.tiktok.com URLs", () => {
    expect(isSupportedUrl("https://vt.tiktok.com/ZSabc123/")).toBe(true);
  });

  it("accepts Instagram reel URLs", () => {
    expect(
      isSupportedUrl("https://www.instagram.com/reel/ABC123xyz/")
    ).toBe(true);
  });

  it("accepts Instagram post URLs (/p/)", () => {
    expect(isSupportedUrl("https://www.instagram.com/p/ABC123xyz/")).toBe(
      true
    );
  });

  it("accepts Instagram TV URLs (/tv/)", () => {
    expect(isSupportedUrl("https://www.instagram.com/tv/ABC123xyz/")).toBe(
      true
    );
  });

  it("rejects YouTube URLs", () => {
    expect(isSupportedUrl("https://www.youtube.com/watch?v=dQw4w9WgXcQ")).toBe(
      false
    );
  });

  it("rejects generic URLs", () => {
    expect(isSupportedUrl("https://google.com")).toBe(false);
  });

  it("rejects empty string", () => {
    expect(isSupportedUrl("")).toBe(false);
  });
});

describe("detectPlatform", () => {
  it("detects tiktok from standard URL", () => {
    expect(
      detectPlatform("https://www.tiktok.com/@user/video/1234567890")
    ).toBe("tiktok");
  });

  it("detects tiktok from vm.tiktok.com", () => {
    expect(detectPlatform("https://vm.tiktok.com/ZMabc123/")).toBe("tiktok");
  });

  it("detects instagram from reel URL", () => {
    expect(
      detectPlatform("https://www.instagram.com/reel/ABC123/")
    ).toBe("instagram");
  });

  it("returns unknown for unsupported URL", () => {
    expect(detectPlatform("https://youtube.com/watch?v=abc")).toBe("unknown");
  });

  it("returns unknown for empty string", () => {
    expect(detectPlatform("")).toBe("unknown");
  });
});

describe("extractUrlFromText", () => {
  it("extracts URL from TikTok share copy text", () => {
    const shareText =
      "Check this recipe! https://vm.tiktok.com/ZMabc123/ via TikTok";
    expect(extractUrlFromText(shareText)).toBe(
      "https://vm.tiktok.com/ZMabc123/"
    );
  });

  it("returns the URL itself when input is just a URL", () => {
    expect(extractUrlFromText("https://vm.tiktok.com/ZMabc123/")).toBe(
      "https://vm.tiktok.com/ZMabc123/"
    );
  });

  it("extracts the first URL when multiple are present", () => {
    const text =
      "See https://vm.tiktok.com/first/ and https://vm.tiktok.com/second/";
    expect(extractUrlFromText(text)).toBe("https://vm.tiktok.com/first/");
  });

  it("returns null when no URL is present", () => {
    expect(extractUrlFromText("just some text no link here")).toBeNull();
  });

  it("returns null for empty string", () => {
    expect(extractUrlFromText("")).toBeNull();
  });
});
