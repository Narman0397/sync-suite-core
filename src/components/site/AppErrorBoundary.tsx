// Root-level error boundary with chunk-load recovery.
// Catches "Failed to fetch dynamically imported module" and similar lazy
// import failures (typically caused by a stale chunk after a new deploy).
// Strategy: attempt a one-shot hard reload; if it keeps failing, show a UI
// that surfaces the SPECIFIC error code/message so it can be acted upon.
import { Component, type ErrorInfo, type ReactNode } from "react";

import { reportLovableError } from "@/lib/lovable-error-reporting";

type State = {
  error: Error | null;
  recovering: boolean;
  code: string;
  detail: string;
  componentStack: string;
  showDetail: boolean;
};

const RELOAD_FLAG = "__lov_chunk_reload";

function isChunkLoadError(err: unknown): boolean {
  const msg = err instanceof Error ? `${err.name}: ${err.message}` : String(err);
  return (
    /Failed to fetch dynamically imported module/i.test(msg) ||
    /Importing a module script failed/i.test(msg) ||
    /ChunkLoadError/i.test(msg) ||
    /Loading chunk \d+ failed/i.test(msg)
  );
}

/** Kode ringkas & stabil supaya bisa dicocokkan dengan log server. */
function classifyError(err: unknown): string {
  const msg = err instanceof Error ? `${err.name}: ${err.message}` : String(err);
  if (isChunkLoadError(err)) return "APP-CHUNK-LOAD";
  if (/Unauthorized|401/i.test(msg)) return "APP-AUTH-401";
  if (/Forbidden|403|row-level security|permission denied/i.test(msg)) return "APP-PERMISSION-403";
  if (/Not Found|404/i.test(msg)) return "APP-NOT-FOUND-404";
  if (/column .* does not exist|relation .* does not exist|PGRST|22P02|23\d{3}/i.test(msg))
    return "APP-DB-QUERY";
  if (/NetworkError|Failed to fetch|ERR_NETWORK|TypeError: fetch/i.test(msg))
    return "APP-NETWORK";
  if (/Hydration|#418|#423|#425/i.test(msg)) return "APP-HYDRATION";
  if (/Minified React error #(\d+)/i.test(msg))
    return `APP-REACT-${/Minified React error #(\d+)/i.exec(msg)?.[1] ?? "UNKNOWN"}`;
  if (err instanceof Error && err.name && err.name !== "Error")
    return `APP-${err.name.replace(/[^A-Za-z0-9]/g, "").toUpperCase()}`;
  return "APP-UNHANDLED";
}

function shortRef(): string {
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 6)}`.toUpperCase();
}

export class AppErrorBoundary extends Component<{ children: ReactNode }, State> {
  state: State = {
    error: null,
    recovering: false,
    code: "",
    detail: "",
    componentStack: "",
    showDetail: false,
  };

  static getDerivedStateFromError(error: Error): Partial<State> {
    return {
      error,
      recovering: false,
      code: classifyError(error),
      detail: error instanceof Error ? `${error.name}: ${error.message}` : String(error),
    };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    if (typeof window === "undefined") return;
    if (isChunkLoadError(error)) {
      try {
        const already = sessionStorage.getItem(RELOAD_FLAG);
        if (!already) {
          sessionStorage.setItem(RELOAD_FLAG, "1");
          this.setState({ recovering: true });
          // Force fresh bundle fetch
          setTimeout(() => window.location.reload(), 150);
          return;
        }
      } catch {
        /* sessionStorage blocked — fall through */
      }
    }
    const code = classifyError(error);
    this.setState({ componentStack: info.componentStack ?? "" });
    // eslint-disable-next-line no-console
    console.error(`[${code}] AppErrorBoundary`, error, info.componentStack);
    reportLovableError(error, { code, componentStack: info.componentStack });
  }

  reset = () => {
    try {
      sessionStorage.removeItem(RELOAD_FLAG);
    } catch {
      /* ignore */
    }
    this.setState({ error: null, recovering: false, showDetail: false });
    if (typeof window !== "undefined") window.location.reload();
  };

  copyDetail = async () => {
    const payload = [
      `Kode: ${this.state.code}`,
      `Pesan: ${this.state.detail}`,
      `Halaman: ${typeof window !== "undefined" ? window.location.href : "-"}`,
      `Waktu: ${new Date().toISOString()}`,
      this.state.error?.stack ? `Stack:\n${this.state.error.stack}` : "",
      this.state.componentStack ? `Komponen:\n${this.state.componentStack}` : "",
    ]
      .filter(Boolean)
      .join("\n");
    try {
      await navigator.clipboard.writeText(payload);
    } catch {
      /* clipboard blocked */
    }
  };

  render() {
    if (this.state.recovering) {
      return (
        <div className="flex min-h-screen items-center justify-center bg-background text-sm text-muted-foreground">
          Memuat ulang aplikasi…
        </div>
      );
    }
    if (this.state.error) {
      const ref = shortRef();
      return (
        <div className="flex min-h-screen items-center justify-center bg-background px-4 py-8">
          <div className="w-full max-w-lg rounded-xl border border-border bg-card p-6 text-left shadow-soft">
            <h1 className="font-display text-xl font-bold text-foreground">Terjadi kesalahan</h1>
            <p className="mt-2 text-sm text-muted-foreground">
              Aplikasi mengalami gangguan. Salin kode di bawah bila perlu melaporkannya.
            </p>

            <dl className="mt-4 space-y-2 rounded-lg bg-muted/50 p-3 text-xs">
              <div className="flex gap-2">
                <dt className="w-20 shrink-0 text-muted-foreground">Kode</dt>
                <dd className="font-mono font-semibold text-foreground">{this.state.code}</dd>
              </div>
              <div className="flex gap-2">
                <dt className="w-20 shrink-0 text-muted-foreground">Referensi</dt>
                <dd className="font-mono text-foreground">{ref}</dd>
              </div>
              <div className="flex gap-2">
                <dt className="w-20 shrink-0 text-muted-foreground">Pesan</dt>
                <dd className="break-words font-mono text-foreground">{this.state.detail}</dd>
              </div>
            </dl>

            {(this.state.error.stack || this.state.componentStack) && (
              <>
                <button
                  onClick={() => this.setState((s) => ({ showDetail: !s.showDetail }))}
                  className="mt-3 text-xs font-medium text-primary underline-offset-2 hover:underline"
                >
                  {this.state.showDetail ? "Sembunyikan detail teknis" : "Lihat detail teknis"}
                </button>
                {this.state.showDetail && (
                  <pre className="mt-2 max-h-64 overflow-auto rounded-lg bg-muted p-3 text-[11px] leading-relaxed text-muted-foreground">
                    {this.state.error.stack ?? ""}
                    {this.state.componentStack ? `\n${this.state.componentStack}` : ""}
                  </pre>
                )}
              </>
            )}

            <div className="mt-5 flex flex-wrap gap-2">
              <button
                onClick={this.reset}
                className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90"
              >
                Muat ulang
              </button>
              <button
                onClick={this.copyDetail}
                className="inline-flex items-center justify-center rounded-md border border-border px-4 py-2 text-sm font-medium text-foreground hover:bg-muted"
              >
                Salin kode error
              </button>
              <a
                href="/"
                className="inline-flex items-center justify-center rounded-md px-4 py-2 text-sm font-medium text-muted-foreground hover:text-foreground"
              >
                Kembali ke beranda
              </a>
            </div>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}
