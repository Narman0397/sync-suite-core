import { createStart, createCsrfMiddleware, createMiddleware } from "@tanstack/react-start";

import { classifyServerError, describeServerError, renderErrorPage } from "./lib/error-page";
import { attachSupabaseAuth } from "@/integrations/supabase/auth-attacher";

const errorMiddleware = createMiddleware().server(async ({ next }) => {
  try {
    return await next();
  } catch (error) {
    if (error != null && typeof error === "object" && "statusCode" in error) {
      throw error;
    }
    const code = classifyServerError(error);
    const reference = `${Date.now().toString(36)}`.toUpperCase();
    console.error(`[${code}] ref=${reference}`, error);
    return new Response(
      renderErrorPage({
        code,
        reference,
        message: describeServerError(error).slice(0, 300),
        status: 500,
      }),
      {
        status: 500,
        headers: {
          "content-type": "text/html; charset=utf-8",
          "x-error-code": code,
          "x-error-ref": reference,
        },
      },
    );
  }
});

// Start installs this automatically when src/start.ts is absent; defining the
// file opts out, so re-add it explicitly to keep server functions protected
// from cross-site requests.
const csrfMiddleware = createCsrfMiddleware({
  filter: (ctx) => ctx.handlerType === "serverFn",
});

export const startInstance = createStart(() => ({
  functionMiddleware: [attachSupabaseAuth],
  requestMiddleware: [errorMiddleware, csrfMiddleware],
}));
