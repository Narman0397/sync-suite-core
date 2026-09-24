// Integration-managed protected layout.
// ssr: false because Supabase session lives in localStorage (server can't read it).
// Redirects unauthenticated users to /auth before any child route loader runs.
//
// Hardening: a transient failure (network blip, in-flight token refresh, slow
// preview session broker) must NOT be treated as "not signed in". We only
// redirect when there is definitively no session, or when the server rejects
// the token as invalid/expired and refresh fails.
import { createFileRoute, Outlet, redirect } from "@tanstack/react-router";
import { supabase } from "@/integrations/supabase/client";

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

function isAuthRejection(message: string): boolean {
  const m = message.toLowerCase();
  return (
    m.includes("invalid claim") ||
    m.includes("jwt expired") ||
    m.includes("token is expired") ||
    m.includes("invalid token") ||
    m.includes("session_not_found") ||
    m.includes("user_not_found") ||
    m.includes("refresh_token_not_found") ||
    m.includes("bad_jwt") ||
    m.includes("not authenticated")
  );
}

export const Route = createFileRoute("/_authenticated")({
  ssr: false,
  beforeLoad: async ({ location }) => {
    const toAuth = (reason: string) => {
      console.warn(`[AUTH-GATE] redirect to /auth — ${reason} (${location.href})`);
      return redirect({ to: "/auth", search: { redirect: location.href } });
    };

    // 1) Local session first — cheap and offline-safe.
    const { data: sessionData } = await supabase.auth.getSession();
    if (!sessionData.session) {
      throw toAuth("no local session");
    }

    // 2) Validate with the auth server, tolerating transient failures.
    let lastMessage = "";
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        const { data, error } = await supabase.auth.getUser();
        if (data?.user) return { user: data.user };
        lastMessage = error?.message ?? "no user returned";
        if (error && isAuthRejection(error.message)) {
          // Token genuinely rejected: try one refresh before giving up.
          const { data: refreshed } = await supabase.auth.refreshSession();
          if (refreshed?.user) return { user: refreshed.user };
          throw toAuth(`token rejected: ${error.message}`);
        }
      } catch (e) {
        if (e != null && typeof e === "object" && "to" in e) throw e; // redirect
        lastMessage = e instanceof Error ? e.message : String(e);
      }
      if (attempt === 0) await sleep(400);
    }

    // Transient failure: keep the session and let the page render. Per-page
    // permission checks and RLS still apply, so nothing is exposed.
    console.warn(`[AUTH-GATE] verification unavailable, keeping session — ${lastMessage}`);
    return { user: sessionData.session.user };
  },
  component: () => <Outlet />,
});
