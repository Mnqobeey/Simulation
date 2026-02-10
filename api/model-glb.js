export default function handler(req, res) {
  const prompt = String(req.query?.prompt || "").toLowerCase();

  let file = null;
  if (prompt.includes("duck")) file = "/assets/library/duck.glb";
  if (prompt.includes("lamp")) file = "/assets/library/lamp.glb";

  if (!file) {
    res.status(404).json({ error: "No static GLB for prompt", prompt });
    return;
  }

  res.setHeader("Cache-Control", "no-store");
  res.writeHead(302, { Location: file });
  res.end();
}
