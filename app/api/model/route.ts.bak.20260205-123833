import { NextResponse } from "next/server";
import OpenAI from "openai";

export const runtime = "nodejs"; // ensure Node runtime on Vercel

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function generateEducationalDescription(prompt: string) {
  const instruction = `
You are an instructional safety & training assistant.
Given an object description, write a short educational description for learners.

Rules:
- 2–3 sentences max.
- Explain what it is + where it is commonly used.
- If relevant, include ONE simple safety or handling tip.
- No markdown, no bullet points, plain text only.
- If the object is abstract (e.g., "yellow sphere"), describe likely uses in training/visualization.
`.trim();

  const resp = await openai.responses.create({
    model: "gpt-4.1-mini",
    input: [
      { role: "system", content: instruction },
      { role: "user", content: `Object: ${prompt}` },
    ],
  });

  return (
    resp.output_text?.trim() ||
    "This item can be used as a visual training aid to support identification, labeling, and scenario-based learning."
  );
}

export async function POST(req: Request) {
  const headers = { "x-nexera-handler": "app-route-ts-v3" };

  try {
    const body = await req.json().catch(() => ({}));
    const prompt = String(body?.prompt || "").trim();

    if (!prompt) {
      return NextResponse.json({ error: "Missing prompt" }, { status: 400, headers });
    }

    // Keep your stages as-is
    const stages = [
      { name: "parse_prompt", pct: 10, status: "done" },
      { name: "generate_mesh", pct: 60, status: "done" },
      { name: "optimize_gltf", pct: 90, status: "done" },
      { name: "publish", pct: 100, status: "done" },
    ];

    // Keep your current URL selection logic
    const p = prompt.toLowerCase();
    let url: string;
    if (p.includes("duck")) url = "/api/model-glb?prompt=duck";
    else if (p.includes("lamp")) url = "/api/model-glb?prompt=lamp";
    else url = `/api/model-glb?prompt=${encodeURIComponent(prompt)}`;

    // NEW: generate educational description for any prompt
    const description = await generateEducationalDescription(prompt);

    return NextResponse.json(
      { stages, model: { url }, description },
      { status: 200, headers }
    );
  } catch (e: any) {
    return NextResponse.json(
      { error: "API crashed", detail: e?.message ?? String(e) },
      { status: 500, headers }
    );
  }
}
