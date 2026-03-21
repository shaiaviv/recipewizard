import { describe, it, expect, vi, beforeEach } from "vitest";
import { parseClaudeResponse } from "../services/claudeService";

// Mock the Anthropic SDK so tests never make real API calls
vi.mock("@anthropic-ai/sdk", () => {
  const MockAnthropic = function (this: unknown) {
    (this as { messages: unknown }).messages = { create: vi.fn() };
  };
  return { default: MockAnthropic };
});

const VALID_RECIPE_JSON = {
  title: "Garlic Butter Pasta",
  cook_time_minutes: 20,
  prep_time_minutes: 10,
  servings: 2,
  difficulty: "easy",
  tags: ["pasta", "quick", "dinner"],
  ingredients: [
    { name: "pasta", quantity: "200", unit: "g", notes: null },
    { name: "garlic", quantity: "3", unit: "cloves", notes: "minced" },
  ],
  steps: [
    { step_number: 1, instruction: "Boil water and cook pasta.", duration_minutes: 10 },
    { step_number: 2, instruction: "Sauté garlic in butter.", duration_minutes: 5 },
  ],
  confidence: 0.9,
};

describe("parseClaudeResponse", () => {
  it("parses a valid ```json block", () => {
    const input = "```json\n" + JSON.stringify(VALID_RECIPE_JSON) + "\n```";
    const result = parseClaudeResponse(input);
    expect(result.title).toBe("Garlic Butter Pasta");
    expect(result.cook_time_minutes).toBe(20);
    expect(result.ingredients).toHaveLength(2);
    expect(result.steps).toHaveLength(2);
    expect(result.confidence).toBe(0.9);
  });

  it("falls back to raw JSON when no code block is present", () => {
    const input = JSON.stringify(VALID_RECIPE_JSON);
    const result = parseClaudeResponse(input);
    expect(result.title).toBe("Garlic Butter Pasta");
  });

  it("throws when response contains neither JSON block nor valid JSON", () => {
    expect(() => parseClaudeResponse("Sorry, I cannot help with that.")).toThrow(
      "Claude response did not contain valid JSON"
    );
  });

  it("throws when the JSON block contains malformed JSON", () => {
    const input = "```json\n{ title: bad json }\n```";
    expect(() => parseClaudeResponse(input)).toThrow();
  });

  it("handles a response with extra whitespace in the code block", () => {
    const input = "```json\n\n  " + JSON.stringify({ title: "Soup" }) + "\n\n```";
    const result = parseClaudeResponse(input);
    expect(result.title).toBe("Soup");
  });

  it("parses partial objects (missing fields)", () => {
    const minimal = { title: "Minimal Recipe" };
    const input = "```json\n" + JSON.stringify(minimal) + "\n```";
    const result = parseClaudeResponse(input);
    expect(result.title).toBe("Minimal Recipe");
    expect(result.cook_time_minutes).toBeUndefined();
  });
});
