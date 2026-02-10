export async function GET(req: Request) {
  const url = new URL(req.url);
  const prompt = String(url.searchParams.get("prompt") || "").toLowerCase();

  let file: string | null = null;
  if (prompt.includes("duck")) file = "/assets/library/duck.glb";
  else if (prompt.includes("lamp")) file = "/assets/library/lamp.glb";

  if (!file) {
    return new Response(JSON.stringify({ error: "No static GLB for prompt", prompt }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  }

  return Response.redirect(new URL(file, url.origin), 302);
}

export async function POST(req: Request) {
  const url = new URL(req.url);
  try {
    const b = await req.json();
    const bodyPrompt = String(b?.prompt || "").trim();
    if (bodyPrompt) url.searchParams.set("prompt", bodyPrompt);
  } catch {}
  return GET(new Request(url.toString(), { method: "GET" }));
}
