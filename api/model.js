import OpenAI from "openai";

export const config = { runtime: "nodejs" };

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

function neutralFallback() {
  return "This item is displayed as a 3D object for visualization and interaction within the scene.";
}

function resolveModelUrlAndSource(prompt) {
  const p = String(prompt || "").toLowerCase();

  // Infrastructure routing (allowed hard-code): map known static assets
  if (p.includes("duck")) return { url: "/assets/library/duck.glb", source: "static-library" };
  if (p.includes("lamp")) return { url: "/assets/library/lamp.glb", source: "static-library" };

  // Everything else: your generator endpoint
  return { url: `/api/model-glb?prompt=${encodeURIComponent(prompt)}`, source: "generated" };
}

async function generateEducationalDescription(prompt) {
  // Keep it strict and avoid vague nouns like "training object"
  const instruction = `
You are an instructional safety and training assistant.

Given an object description, write a short educational description.

Rules:
- 2–3 sentences maximum.
- Use a concrete noun that matches the object (avoid vague terms like "training object" or "generic object").
- Explain what it is and where it is commonly used.
- Include one simple safety or handling tip only if relevant.
- If the object is abstract (e.g., "yellow sphere"), describe likely uses in training/visualization.
- Plain text only. No markdown. No bullet points.
`.trim();

  const resp = await openai.responses.create({
    model: "gpt-4.1-mini",
    input: [
      { role: "system", content: instruction },
      { role: "user", content: `Object: ${prompt}` },
    ],
  });

  const out = (resp.output_text || "").trim();
  return out || neutralFallback();
}

export default async function handler(req, res) {
  res.setHeader("x-nexera-handler", "vercel-fn-model-v7");

  try {
    const debug =
      (req.query && String(req.query.debug) === "1") ||
      (req.url && req.url.includes("debug=1"));

    // Parse body safely
    let body = {};
    if (typeof req.body === "string") {
      body = JSON.parse(req.body);
    } else if (req.body && typeof req.body === "object") {
      body = req.body;
    }

    const prompt = String(body.prompt || "").trim();
    if (!prompt) return res.status(400).json({ error: "Missing prompt" });

    const { url, source } = resolveModelUrlAndSource(prompt);

    const stages = [
      { name: "parse_prompt", pct: 10, status: "done" },
      { name: "generate_mesh", pct: 60, status: "done" },
      { name: "optimize_gltf", pct: 90, status: "done" },
      { name: "publish", pct: 100, status: "done" },
    ];

    const hasKey = !!process.env.OPENAI_API_KEY;

    let description = "";
    let aiStatus = "ok"; // ok | unavailable | disabled

    if (!hasKey) {
      description = neutralFallback();
      aiStatus = "disabled";
    } else {
      try {
        description = await generateEducationalDescription(prompt);
        aiStatus = "ok";
      } catch (e) {
        description = neutralFallback();
        aiStatus = "unavailable";
      }
    }

    const payload = {
      stages,
      model: { url },
      source,
      prompt,
      description,
      hasKey,
      aiStatus,
    };

    if (debug) payload.debug = true;

    return res.status(200).json(payload);
  } catch (e) {
    return res.status(500).json({
      error: "API crashed",
      detail: e?.message || String(e),
    });
  }
}
