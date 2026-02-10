export type ModelStage = {
  name: string;
  pct: number;
  status: "pending" | "running" | "done" | "error";
  detail?: string;
};

export type ModelPlan = {
  stages: ModelStage[];
  model: {
    url: string;
  };

  
  prompt?: string;
  source?: string;
  description?: string;
  hasKey?: boolean;
  aiStatus?: "ok" | "fallback" | "disabled";
};

export async function fetchModelPlan(prompt: string): Promise<ModelPlan> {
  const res = await fetch("/api/model", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ prompt }),
    
  });

  // Parse JSON safely
  let data: any;
  try {
    data = await res.json();
  } catch {
    const txt = await res.text().catch(() => "");
    throw new Error(`API /api/model returned non-JSON: ${res.status} ${txt}`);
  }

  if (!res.ok) {
    throw new Error(data?.detail || data?.error || `API /api/model failed: ${res.status}`);
  }

  const url = data?.model?.url;
  if (!url || typeof url !== "string") {
    throw new Error("API /api/model missing model.url");
  }

  return {
    stages: Array.isArray(data?.stages) ? data.stages : [],
    model: { url },

    prompt: typeof data?.prompt === "string" ? data.prompt : prompt,
    source: typeof data?.source === "string" ? data.source : undefined,
    description: typeof data?.description === "string" ? data.description : undefined,
    hasKey: typeof data?.hasKey === "boolean" ? data.hasKey : undefined,
    aiStatus:
      data?.aiStatus === "ok" || data?.aiStatus === "fallback" || data?.aiStatus === "disabled"
        ? data.aiStatus
        : undefined,
  };
}
