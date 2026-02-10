export default async function handler(req, res) {
  try {
    res.setHeader("x-nexera-handler", "local-index-v3");

    const method = req.method || "GET";

    if (method === "GET") {
      return res.status(200).json({ ok: true, service: "nexera-text-to-3d", status: "alive" });
    }

    if (method !== "POST") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    // body can be object OR string in some dev setups
    let body = req.body;
    if (typeof body === "string") {
      try { body = JSON.parse(body); }
      catch { return res.status(400).json({ error: "Invalid JSON" }); }
    }

    const prompt = String(body?.prompt || "").trim();
    if (!prompt) {
      return res.status(400).json({ error: "Missing prompt" });
    }

    // ✅ NEW contract
    const stages = [
      { name: "parse_prompt", pct: 10, status: "done" },
      { name: "generate_mesh", pct: 60, status: "done" },
      { name: "optimize_gltf", pct: 90, status: "done" },
      { name: "publish", pct: 100, status: "done" },
    ];

    // ✅ IMPORTANT: point to the REAL binary endpoint (NOT /api/model)
    const url = `/api/model-glb?prompt=${encodeURIComponent(prompt)}`;

    return res.status(200).json({ stages, model: { url } });
  } catch (err) {
    return res.status(500).json({ error: err?.message || "Server error" });
  }
}
