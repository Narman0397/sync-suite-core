import { useEffect } from "react";
import {
  Outlet,
  Link,
  createRootRouteWithContext,
  HeadContent,
  Scripts,
} from "@tanstack/react-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { AuthProvider } from "@/lib/auth-context";
import { Toaster } from "@/components/ui/sonner";
import { PushAutoEnable } from "@/components/site/PushAutoEnable";
import { PermohonanNotifier } from "@/components/site/PermohonanNotifier";
import { InstallPWAFloating } from "@/components/site/InstallPWAFloating";
import { DynamicBrandingHead } from "@/components/site/DynamicBrandingHead";
import { AppErrorBoundary } from "@/components/site/AppErrorBoundary";
import { registerPWA } from "@/lib/pwa-register";
import { VerificationGate } from "@/components/site/VerificationGate";
import { siteBrandingQueryOptions } from "@/lib/site-settings";
import { reportLovableError } from "@/lib/lovable-error-reporting";


import appCss from "../styles.css?url";

interface RouterContext {
  queryClient: QueryClient;
}

function RouteErrorComponent({ error, reset }: { error: Error; reset: () => void }) {
  useEffect(() => {
    console.error("[ROUTE-ERROR]", error);
    reportLovableError(error, { boundary: "tanstack_root_error_component" });
  }, [error]);
  const code =
    (error as { code?: string }).code ??
    (error.name && error.name !== "Error" ? `ROUTE-${error.name.toUpperCase()}` : "ROUTE-ERROR");
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4 py-8">
      <div className="w-full max-w-lg rounded-xl border border-border bg-card p-6 shadow-soft">
        <h1 className="font-display text-xl font-bold text-foreground">Halaman gagal dimuat</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Sertakan kode berikut bila perlu melaporkan masalah ini.
        </p>
        <div className="mt-4 space-y-2 rounded-lg bg-muted/50 p-3 text-xs">
          <div className="flex gap-2">
            <span className="w-20 shrink-0 text-muted-foreground">Kode</span>
            <span className="font-mono font-semibold text-foreground">{code}</span>
          </div>
          <div className="flex gap-2">
            <span className="w-20 shrink-0 text-muted-foreground">Pesan</span>
            <span className="break-words font-mono text-foreground">{error.message}</span>
          </div>
        </div>
        {error.stack && (
          <pre className="mt-3 max-h-56 overflow-auto rounded-lg bg-muted p-3 text-[11px] text-muted-foreground">
            {error.stack}
          </pre>
        )}
        <div className="mt-5 flex flex-wrap gap-2">
          <button
            onClick={reset}
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90"
          >
            Coba lagi
          </button>
          <Link
            to="/"
            className="inline-flex items-center justify-center rounded-md border border-border px-4 py-2 text-sm font-medium text-foreground hover:bg-muted"
          >
            Kembali ke beranda
          </Link>
        </div>
      </div>
    </div>
  );
}

function NotFoundComponent() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="max-w-md text-center">
        <h1 className="text-7xl font-bold text-foreground">404</h1>
        <h2 className="mt-4 text-xl font-semibold text-foreground">Page not found</h2>
        <p className="mt-2 text-sm text-muted-foreground">
          The page you're looking for doesn't exist or has been moved.
        </p>
        <div className="mt-6">
          <Link
            to="/"
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90"
          >
            Go home
          </Link>
        </div>
      </div>
    </div>
  );
}

export const Route = createRootRouteWithContext<RouterContext>()({
  // Branding dipastikan sudah termuat SEBELUM render SSR. Tanpa ini, HTML
  // server memakai nilai bawaan sementara cache yang di-dehydrate ke klien
  // sudah berisi data asli → teks/logo berbeda saat hidrasi (React #418).
  loader: async ({ context }) => {
    await context.queryClient.ensureQueryData(siteBrandingQueryOptions());
  },
  head: () => ({
    meta: [
      { charSet: "utf-8" },
      { name: "viewport", content: "width=device-width, initial-scale=1, viewport-fit=cover" },
      { name: "theme-color", content: "#0F172A" },
      { name: "mobile-web-app-capable", content: "yes" },
      { name: "apple-mobile-web-app-capable", content: "yes" },
      { name: "apple-mobile-web-app-status-bar-style", content: "black-translucent" },
      { name: "application-name", content: "Portal Kabupaten Buton Selatan" },
      { title: "Pemerintah Kabupaten Buton Selatan — Portal Resmi & Satu Data" },
      {
        name: "description",
        content:
          "Portal resmi pelayanan publik dan satu data Kabupaten Buton Selatan. Ajukan layanan, lihat statistik, dan pantau kinerja pemerintah.",
      },
      { name: "author", content: "Lovable" },
      { property: "og:title", content: "Pemerintah Kabupaten Buton Selatan — Portal Resmi & Satu Data" },
      {
        property: "og:description",
        content:
          "Portal resmi pelayanan publik dan satu data Kabupaten Buton Selatan. Ajukan layanan, lihat statistik, dan pantau kinerja pemerintah.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
      { name: "twitter:site", content: "@Lovable" },
      { name: "twitter:title", content: "Pemerintah Kabupaten Buton Selatan — Portal Resmi & Satu Data" },
      {
        name: "twitter:description",
        content:
          "Portal resmi pelayanan publik dan satu data Kabupaten Buton Selatan. Ajukan layanan, lihat statistik, dan pantau kinerja pemerintah.",
      },
      {
        property: "og:image",
        content:
          "https://storage.googleapis.com/gpt-engineer-file-uploads/attachments/og-images/fee199aa-ab79-4d95-9266-7b058bde67e9",
      },
      {
        name: "twitter:image",
        content:
          "https://storage.googleapis.com/gpt-engineer-file-uploads/attachments/og-images/fee199aa-ab79-4d95-9266-7b058bde67e9",
      },
      { name: "description", content: "Portal resmi pelayanan publik dan satu data Kabupaten Buton Selatan. Ajukan layanan, lihat statistik, dan pantau kinerja pemerintah." },
      { property: "og:description", content: "Portal resmi pelayanan publik dan satu data Kabupaten Buton Selatan. Ajukan layanan, lihat statistik, dan pantau kinerja pemerintah." },
      { name: "twitter:description", content: "Portal resmi pelayanan publik dan satu data Kabupaten Buton Selatan. Ajukan layanan, lihat statistik, dan pantau kinerja pemerintah." },
      { property: "og:image", content: "https://storage.googleapis.com/gpt-engineer-file-uploads/attachments/og-images/fee199aa-ab79-4d95-9266-7b058bde67e9" },
      { name: "twitter:image", content: "https://storage.googleapis.com/gpt-engineer-file-uploads/attachments/og-images/fee199aa-ab79-4d95-9266-7b058bde67e9" },
    ],
    links: [
      { rel: "stylesheet", href: appCss },
      { rel: "preconnect", href: "https://fonts.googleapis.com" },
      { rel: "preconnect", href: "https://fonts.gstatic.com", crossOrigin: "anonymous" },
      {
        rel: "preload",
        as: "style",
        href: "https://fonts.googleapis.com/css2?family=Outfit:wght@600;700&family=Figtree:wght@400;500;600&display=swap",
      },
      {
        rel: "stylesheet",
        href: "https://fonts.googleapis.com/css2?family=Outfit:wght@600;700&family=Figtree:wght@400;500;600&display=swap",
      },
      { rel: "manifest", href: "/manifest.webmanifest" },
      { rel: "icon", href: "/icon-192.png", type: "image/png" },
      { rel: "apple-touch-icon", href: "/icon-192.png" },
    ],
  }),
  shellComponent: RootShell,
  component: RootComponent,
  notFoundComponent: NotFoundComponent,
  errorComponent: RouteErrorComponent,
});

function RootShell({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <HeadContent />
      </head>
      <body>
        {children}
        <Scripts />
      </body>
    </html>
  );
}

function RootComponent() {
  const { queryClient } = Route.useRouteContext();
  useEffect(() => {
    registerPWA();
  }, []);
  return (
    <QueryClientProvider client={queryClient}>
      <AppErrorBoundary>
        <AuthProvider>
          <Outlet />
          <DynamicBrandingHead />
          <PushAutoEnable />
          <PermohonanNotifier />
          <InstallPWAFloating />
          <VerificationGate />
          <Toaster />
        </AuthProvider>

      </AppErrorBoundary>
    </QueryClientProvider>
  );
}
