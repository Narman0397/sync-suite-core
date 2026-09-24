# Dashboard Pimpinan Kabupaten — Consolidation & Redesign Plan

PLAN ONLY. No code changed in this task.

## 1. Verified current state (inspected files only)

- `src/routes/_authenticated/executive.tsx` (300 lines) — the executive page. Title on screen says "Dashboard Eksekutif Kabupaten", nav label says "Dashboard Pimpinan".
- `src/routes/_authenticated/pemda.tsx` and `admin.eksekutif.tsx` — already reduced to redirects to `/executive` (redirect work: DONE, verified).
- `src/lib/executive.functions.ts` + `executive.queries.ts` — server functions with auth middleware, executive-role check, RPC `executive_summary` and `opd_skor_komposit`, plus a data-contract validation throw (data contract + security work: DONE, verified).
- `src/components/admin/ExecutiveGuard.tsx` — role gate (super_admin, admin_pemda, pimpinan, kepala_bkpsdm) with loading/not-signed-in/denied states. Verified working.
- `src/components/admin/AdminShell.tsx` — 4 nav entries all pointing to `/executive` with 2 different labels.
- `src/routes/_authenticated/admin.index.tsx` — Super Admin command center (separate audience, not the executive dashboard).
- `admin.governance.tsx`, `admin.system-health.tsx`, `admin.monitoring.*` — operational/detail pages.
- No test files and no test runner in the project.

STATUS SUMMARY
- IMPLEMENTED: redirects, server-side authorization, data contract validation, query options with 60s refetch, role guard.
- PARTIAL: `/executive` page — old layout, 8 uniform small cards, `?? 0` fallbacks everywhere, does not use the prepared `executive.queries.ts` (uses `useEffect` + `useState` instead), does not show the extra fields already returned by the contract (`sla_on_time_pct`, `izin_pending`, `dataset_*`, `generated_at`).
- MISSING: freshness indicator, real empty/error/loading distinction, alert section driven by real exceptions, recent activity, tests.
- BROKEN/WEAK: "Tanda Tangan Pending" is hardcoded `0`; "Semua OPD baik." shown even when there is no OPD data; nav duplication; `permohonan_total/selesai`, `laporan_total`, `asn`/`aset` context unused.

## 2. Canonical decision

- CANONICAL: `/executive` — renamed consistently to "Dashboard Pimpinan Kabupaten" in page heading, head title, and all nav entries.
- DETAIL PAGES (kept, unchanged): `/admin/monitoring/*`, `/admin/governance`, `/admin/system-health`, `/admin/permohonan`, `/admin/laporan`, `/admin/aset`, `/admin/asn`, `/kinerja-opd`.
- REDUNDANT: the duplicate nav entries in `AdminShell.tsx` (keep one per role group, single label).
- `/pemda` and `/admin/eksekutif` redirects stay as-is. Nothing gets deleted.

## 3. Information architecture (target)

1. Header + freshness ("Diperbarui X lalu", from `generated_at`).
2. EXECUTIVE STATUS — 4 hero indicators: SLA on-time %, Permohonan bulan ini, Overdue, Pengaduan aktif.
3. PELAYANAN PUBLIK — total, selesai, backlog (total − selesai), overdue, SLA.
4. PENGADUAN — total, aktif/open. (Belum-ditindaklanjuti & response time: no source → omitted, not faked.)
5. KINERJA OPD — table from `opd_skor_komposit`: OPD, SLA%, backlog, skor. Ranking only shown when ≥5 scored OPD exist; otherwise the full list.
6. ASN & ASET — ASN count, izin pending, total aset, aset rusak.
7. DATA/DOKUMEN — dataset template aktif, submission aktif, review pending.
8. PERLU PERHATIAN — exceptions only: overdue > 0, OPD with SLA < 70, aset rusak > 0, review pending. Empty only when computed from loaded data.
9. AKTIVITAS PENTING — deferred to a later phase unless an existing non-technical source is confirmed.
10. Bupati queue — kept, but "Tanda Tangan Pending" removed or labeled "Sumber data belum tersedia" instead of a fake 0.

## 4. KPI / data source matrix

| KPI | Source | Hook | Status |
|---|---|---|---|
| SLA on-time %, permohonan total/bulan/selesai/overdue, laporan total/open, aset total/rusak, ikm 30d, opd/asn count, izin pending, dataset x3 | RPC `executive_summary` | `executiveSummaryQueryOptions` | AVAILABLE (needs UI) |
| OPD SLA / skor / rating / backlog | RPC `opd_skor_komposit` | `executiveOpdQueryOptions` | AVAILABLE (needs UI) |
| Disposisi aktif, approval pending (Bupati) | direct table counts in page | inline | AVAILABLE |
| Tanda tangan pending | none | none | MISSING SOURCE → show as unavailable |
| Pengaduan belum ditindaklanjuti, response time | none in contract | none | MISSING SOURCE → omit |
| Aktivitas penting | audit_log (technical events) | none | NOT SUITABLE as-is |

## 5. Freshness matrix

- All executive KPIs: NEAR REAL-TIME — 60s polling already configured in `executive.queries.ts`; surface `generated_at` as "Diperbarui N detik/menit lalu".
- Bupati queue: PERIODIC, refetched with the page.
- No new realtime/websocket infrastructure.

## 6. UI/UX plan

Government executive command style: one dense hero strip, then grouped sections with clear section headers, muted surface, accent color only for exceptions. Mobile-first single column with the hero strip in a 2-column grid; desktop 4-column hero and 2-column section grid. Reuse existing tokens and `DashboardSectionHeader`, `DashboardLoadingState`, `DashboardDataNotice`. No gradients beyond existing tokens, no fake charts, no decorative cards.

## 7. States

Per section: loading skeleton / error ("Data … gagal dimuat") / actual zero ("0 pengaduan aktif") / no rows ("Belum ada data …") / missing source ("Sumber data belum tersedia"). Remove all `?? 0` fallbacks so zero and unknown never look the same.

## 8. Security

Verify only, no changes: `ExecutiveGuard` role set, server-side `requireExecutive` check, RLS-backed RPCs. Any defect found gets reported, not silently patched.

## 9. Performance

Replace the page's `useEffect` fetching with the existing query options (dedupe, cache, single 60s poll). Bupati queue becomes one `useQuery` gated on `isBupati`.

## 10. Test plan (no runner exists → browser-driven targeted checks)

- P0: page loads for super_admin and pimpinan; denied for warga/asn; values match RPC output; no hardcoded numbers; redirects `/pemda` and `/admin/eksekutif` still land on `/executive`.
- P1: mobile 360px and desktop 1280px screenshots; empty/error/loading states; freshness label.
- P2: contrast and heading order.
No new test framework, no broad suites.

## 11. Phases

1. Rename + nav de-duplication (canonical dashboard).
2. Switch the page to the existing query options; add freshness and honest states.
3. Information architecture regrouping.
4. Section UI redesign (mobile-first).
5. Exceptions/alert section from real data.
6. Targeted QA with screenshots.

## 12. Files

EXPECTED TO CHANGE
- `src/routes/_authenticated/executive.tsx` (main work)
- `src/components/admin/AdminShell.tsx` (nav labels/duplicates only)
- possibly 1–2 small new components under `src/components/admin/dashboard/`

MUST NOT CHANGE
- `src/lib/executive.functions.ts`, `src/lib/executive.queries.ts`
- `src/components/admin/ExecutiveGuard.tsx`, `AdminGuard.tsx`, `src/lib/supabase-auth-middleware.ts`
- `pemda.tsx`, `admin.eksekutif.tsx`, `admin.index.tsx`, monitoring/governance pages
- database schema, seed, RLS, roles, permissions

## 13. Risks

- `opd_skor_komposit` may return few rows → ranking must degrade gracefully.
- Removing `?? 0` can surface previously hidden errors (desirable, but visible).
- Nav edits touch a shared shell used by several roles — change labels/entries only.

## 14. NEXT IMPLEMENTATION PROMPT

> Implement the approved Dashboard Pimpinan work only, on the current codebase.
> Canonical route: `/executive` (`src/routes/_authenticated/executive.tsx`). Rename heading, head title, and all `AdminShell` nav entries to "Dashboard Pimpinan Kabupaten"; remove duplicate nav entries.
> Rewrite only the page body: use `executiveSummaryQueryOptions` and `executiveOpdQueryOptions` from `src/lib/executive.queries.ts` instead of `useEffect`/`useState`. Do not modify `executive.functions.ts`, `executive.queries.ts`, `ExecutiveGuard.tsx`, `supabase-auth-middleware.ts`, the `/pemda` and `/admin/eksekutif` redirects, `admin.index.tsx`, monitoring/governance pages, database schema, seed, RLS, roles, or permissions.
> Sections in order: freshness header from `generated_at`; hero (SLA on-time %, permohonan bulan ini, overdue, pengaduan aktif); Pelayanan Publik (total, selesai, backlog, overdue, SLA); Pengaduan (total, aktif); Kinerja OPD table from `opd_skor_komposit` with ranking only when ≥5 scored rows; ASN & Aset (asn_count, izin_pending, aset_total, aset_rusak); Data/Dokumen (dataset template aktif, submission aktif, review pending); Perlu Perhatian listing only real exceptions; Bupati queue without the fake "Tanda Tangan Pending" value.
> Remove every `?? 0` fallback. Distinguish loading, actual zero, no rows ("Belum ada data …"), missing source ("Sumber data belum tersedia"), and error ("Data … gagal dimuat").
> Mobile-first, dense, professional government command style using existing design tokens; no gradients beyond tokens, no fake charts, no invented metrics.
> Verify with targeted browser checks at 360px and 1280px as super_admin and pimpinan, and confirm access denial for a warga account. Do not add Call Center, 112, VoIP, SIP, or WebRTC. Do not refactor anything unrelated.
