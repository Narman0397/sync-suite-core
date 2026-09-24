export interface ErrorPageDetail {
  code?: string;
  message?: string;
  reference?: string;
  status?: number;
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/** Kode ringkas untuk error sisi server, agar bisa dicocokkan dengan log. */
export function classifyServerError(error: unknown, status = 500): string {
  const msg =
    error instanceof Error ? `${error.name}: ${error.message}` : String(error ?? "unknown");
  if (/Unauthorized|401/i.test(msg)) return "SSR-AUTH-401";
  if (/Forbidden|403|row-level security|permission denied/i.test(msg)) return "SSR-PERMISSION-403";
  if (/column .* does not exist|relation .* does not exist|PGRST/i.test(msg)) return "SSR-DB-QUERY";
  if (/fetch failed|ECONNREFUSED|ENOTFOUND|NetworkError/i.test(msg)) return "SSR-NETWORK";
  if (/Missing Supabase|environment/i.test(msg)) return "SSR-CONFIG";
  if (/h3 swallowed SSR error/i.test(msg)) return "SSR-UNHANDLED-H3";
  if (error instanceof Error && error.name && error.name !== "Error")
    return `SSR-${error.name.replace(/[^A-Za-z0-9]/g, "").toUpperCase()}`;
  return `SSR-ERROR-${status}`;
}

export function describeServerError(error: unknown): string {
  if (error instanceof Error) return `${error.name}: ${error.message}`;
  if (typeof error === "string") return error;
  try {
    return JSON.stringify(error);
  } catch {
    return "Unknown error";
  }
}

export function renderErrorPage(detail: ErrorPageDetail = {}): string {
  const code = escapeHtml(detail.code ?? `SSR-ERROR-${detail.status ?? 500}`);
  const reference = escapeHtml(
    detail.reference ?? `${Date.now().toString(36)}`.toUpperCase(),
  );
  const message = detail.message ? escapeHtml(detail.message) : "";
  const messageRow = message
    ? `<div class="row"><span class="k">Pesan</span><span class="v">${message}</span></div>`
    : "";
  return `<!doctype html><html lang="id"><head><meta charset="utf-8"/><title>Terjadi Kesalahan — ${code}</title><meta name="viewport" content="width=device-width,initial-scale=1"/><style>body{font-family:system-ui,-apple-system,sans-serif;display:flex;min-height:100vh;align-items:center;justify-content:center;margin:0;background:#0f172a;color:#f8fafc}.card{text-align:left;max-width:34rem;padding:2rem}h1{font-size:1.5rem;margin:0 0 .5rem;text-align:center}p{color:#94a3b8;margin:0 0 1.25rem;text-align:center}.box{background:#1e293b;border-radius:.75rem;padding:1rem;font-size:.8rem;margin-bottom:1.5rem}.row{display:flex;gap:.75rem;margin-bottom:.5rem}.row:last-child{margin-bottom:0}.k{color:#94a3b8;width:5.5rem;flex:none}.v{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}.actions{text-align:center}a{display:inline-block;background:#3b82f6;color:#fff;padding:.5rem 1rem;border-radius:.5rem;text-decoration:none;margin:0 .25rem}a.ghost{background:transparent;border:1px solid #334155;color:#cbd5e1}</style></head><body><div class="card"><h1>Terjadi Kesalahan</h1><p>Halaman tidak bisa dimuat saat ini. Sertakan kode berikut saat melaporkan.</p><div class="box"><div class="row"><span class="k">Kode</span><span class="v">${code}</span></div><div class="row"><span class="k">Referensi</span><span class="v">${reference}</span></div>${messageRow}</div><div class="actions"><a href="javascript:location.reload()">Muat ulang</a><a class="ghost" href="/">Kembali ke Beranda</a></div></div></body></html>`;
}
