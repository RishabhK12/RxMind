export interface Env {
  GEMINI_API_KEY: string;
  BACKEND_SHARED_SECRET?: string;
  ALLOWED_ORIGIN?: string;
}

// Allow simple prompts while keeping room for future expansion
interface GenerateRequestBody {
  prompt?: string;
  model?: string; // default: gemini-2.0-flash
  systemInstruction?: string;
  generationConfig?: {
    temperature?: number;
    topK?: number;
    topP?: number;
    maxOutputTokens?: number;
  };
  contents?: unknown; // advanced raw request passthrough
}

const DEFAULT_MODEL = "gemini-2.0-flash";
const API_BASE = "https://generativelanguage.googleapis.com/v1beta";

function corsHeaders(origin: string) {
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Headers": "content-type,x-api-key",
    "Access-Control-Allow-Methods": "POST,OPTIONS",
  } as Record<string, string>;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // CORS preflight
    if (request.method === "OPTIONS") {
      const origin = env.ALLOWED_ORIGIN ?? "*";
      return new Response(null, { headers: corsHeaders(origin) });
    }

    if (request.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method Not Allowed" }), {
        status: 405,
        headers: { "content-type": "application/json" },
      });
    }

    // Optional shared-secret check to mitigate abuse if the URL leaks
    if (env.BACKEND_SHARED_SECRET) {
      const clientSecret = request.headers.get("x-api-key");
      if (!clientSecret || clientSecret !== env.BACKEND_SHARED_SECRET) {
        return new Response(JSON.stringify({ error: "Unauthorized" }), {
          status: 401,
          headers: { "content-type": "application/json" },
        });
      }
    }

    let body: GenerateRequestBody;
    try {
      body = (await request.json()) as GenerateRequestBody;
    } catch {
      return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
        status: 400,
        headers: { "content-type": "application/json" },
      });
    }

    const model = (body.model || DEFAULT_MODEL).trim();

    // Build request payload for Gemini API
    let payload: any;
    if (body.contents) {
      // advanced passthrough
      payload = { ...body };
    } else {
      const prompt = (body.prompt ?? "").toString();
      if (!prompt) {
        return new Response(JSON.stringify({ error: "Missing 'prompt'" }), {
          status: 400,
          headers: { "content-type": "application/json" },
        });
      }
      payload = {
        // Use same shape as working direct client: no 'role' field for systemInstruction
        systemInstruction: body.systemInstruction
          ? { parts: [{ text: body.systemInstruction }] }
          : undefined,
        contents: [
          {
            role: "user",
            parts: [{ text: prompt }],
          },
        ],
        generationConfig: body.generationConfig ?? {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        },
      };
    }

    const endpoint = `${API_BASE}/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(
      env.GEMINI_API_KEY
    )}`;

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort("timeout"), 15000); // 15s

    try {
      const r = await fetch(endpoint, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(payload),
        signal: controller.signal,
      });
      clearTimeout(timeout);

      const origin = env.ALLOWED_ORIGIN ?? "*";

      if (!r.ok) {
        const text = await r.text();
        // If we included systemInstruction and got a 400 complaining about system_instruction, retry without it once.
        let retried = false;
        if (
          r.status === 400 &&
          payload.systemInstruction &&
          /system_instruction\.parts\[0\]/i.test(text)
        ) {
          retried = true;
          const retryPayload = { ...payload };
          delete retryPayload.systemInstruction;
          const r2 = await fetch(endpoint, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify(retryPayload),
            signal: controller.signal,
          });
          if (r2.ok) {
            const json2 = await r2.json();
            const text2 =
              json2?.candidates?.[0]?.content?.parts?.map((p: any) => p?.text).filter(Boolean).join("\n") ?? null;
            return new Response(
              JSON.stringify({ text: text2, raw: json2, retriedWithoutSystemInstruction: true }),
              { headers: { "content-type": "application/json", ...corsHeaders(origin) } }
            );
          } else {
            const t2 = await r2.text();
            return new Response(
              JSON.stringify({
                error: "Upstream error",
                status: r2.status,
                body: t2,
                originalStatus: r.status,
                originalBody: text,
                retriedWithoutSystemInstruction: true,
              }),
              { status: 502, headers: { "content-type": "application/json", ...corsHeaders(origin) } }
            );
          }
        }
        return new Response(
          JSON.stringify({ error: "Upstream error", status: r.status, body: text, payloadEcho: payload, retried }),
          { status: 502, headers: { "content-type": "application/json", ...corsHeaders(origin) } }
        );
      }

      const json = await r.json();

      // Try to extract the first text candidate for convenience
      const text =
        json?.candidates?.[0]?.content?.parts?.map((p: any) => p?.text).filter(Boolean).join("\n") ?? null;

      return new Response(JSON.stringify({ text, raw: json }), {
        headers: { "content-type": "application/json", ...corsHeaders(origin) },
      });
    } catch (e: any) {
      const origin = env.ALLOWED_ORIGIN ?? "*";
      const message = e?.name === "AbortError" ? "Request timed out" : e?.message || "Request failed";
      return new Response(JSON.stringify({ error: message }), {
        status: 500,
        headers: { "content-type": "application/json", ...corsHeaders(origin) },
      });
    }
  },
};
