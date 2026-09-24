import "./lib/error-capture";

import { consumeLastCapturedError } from "./lib/error-capture";
import { classifyServerError, describeServerError, renderErrorPage } from "./lib/error-page";
import { applyEdgeCache } from "./lib/edge-cache";
import { hydrateProcessEnv } from "./lib/worker-env";

type ServerEntry = {
  fetch: (request: Request, env: unknown, ctx: unknown) => Promise<Response> | Response;
};

let serverEntryPromise: Promise<ServerEntry> | undefined;

async function getServerEntry(): Promise<ServerEntry> {
  if (!serverEntryPromise) {
    serverEntryPromise = import("@tanstack/react-start/server-entry").then(
      (m) => (m as { default?: ServerEntry }).default ?? (m as unknown as ServerEntry),
    );
  }
  return serverEntryPromise;
}

function brandedErrorResponse(error?: unknown, status = 500): Response {
  const code = classifyServerError(error, status);
  const message = error === undefined ? undefined : describeServerError(error).slice(0, 300);
  const reference = `${Date.now().toString(36)}`.toUpperCase();
  console.error(`[${code}] ref=${reference} ${message ?? ""}`);
  return new Response(renderErrorPage({ code, message, reference, status }), {
    status,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "x-error-code": code,
      "x-error-ref": reference,
    },
  });
}

function isCatastrophicSsrErrorBody(body: string, responseStatus: number): boolean {
  let payload: unknown;
  try {
    payload = JSON.parse(body);
  } catch {
    return false;
  }

  if (!payload || Array.isArray(payload) || typeof payload !== "object") {
    return false;
  }

  const fields = payload as Record<string, unknown>;
  const expectedKeys = new Set(["message", "status", "unhandled"]);
  if (!Object.keys(fields).every((key) => expectedKeys.has(key))) {
    return false;
  }

  return (
    fields.unhandled === true &&
    fields.message === "HTTPError" &&
    (fields.status === undefined || fields.status === responseStatus)
  );
}

// h3 swallows in-handler throws into a normal 500 Response with body
// {"unhandled":true,"message":"HTTPError"} — try/catch alone never fires for those.
async function normalizeCatastrophicSsrResponse(response: Response): Promise<Response> {
  if (response.status < 500) return response;
  const contentType = response.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) return response;

  const body = await response.clone().text();
  if (!isCatastrophicSsrErrorBody(body, response.status)) {
    return response;
  }

  const captured = consumeLastCapturedError() ?? new Error(`h3 swallowed SSR error: ${body}`);
  console.error(captured);
  return brandedErrorResponse(captured, response.status);
}

export default {
  async fetch(request: Request, env: unknown, ctx: unknown) {
    // Must run before anything reads process.env (Supabase clients, auth
    // middleware, cron auth). Cloudflare passes config/secrets via `env`.
    hydrateProcessEnv(env);
    try {
      const handler = await getServerEntry();
      const raw = await handler.fetch(request, env, ctx);
      const response = await normalizeCatastrophicSsrResponse(raw);

      // Hanya menempelkan header Cache-Control/Vary. JANGAN pernah meng-clone
      // atau membaca body SSR di sini: body-nya stream, dan meng-clone-nya
      // membuat respons tidak pernah selesai di Cloudflare Workers.
      const cacheable = applyEdgeCache(request, response);
      return cacheable ?? response;
    } catch (error) {
      console.error(error);
      return brandedErrorResponse(error);
    }
  },
};
