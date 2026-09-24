// Reverse geocoding: koordinat → nama lokasi (OpenStreetMap Nominatim) + deteksi kantor OPD terdekat.
import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/lib/supabase-auth-middleware";

type Result = { place: string | null; kantor: string | null; distance_m: number | null };

const cache = new Map<string, { at: number; place: string | null }>();
const TTL = 1000 * 60 * 60 * 24;

function haversine(lat1: number, lng1: number, lat2: number, lng2: number) {
  const R = 6371000;
  const r = (d: number) => (d * Math.PI) / 180;
  const a =
    Math.sin(r(lat2 - lat1) / 2) ** 2 +
    Math.cos(r(lat1)) * Math.cos(r(lat2)) * Math.sin(r(lng2 - lng1) / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

async function lookupPlace(lat: number, lng: number): Promise<string | null> {
  // Bulatkan ~11 m agar cache efektif & hemat panggilan.
  const key = `${lat.toFixed(4)},${lng.toFixed(4)}`;
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < TTL) return hit.place;
  try {
    const url = `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${lat}&lon=${lng}&zoom=17&accept-language=id&addressdetails=1`;
    const res = await fetch(url, {
      headers: { "User-Agent": "PortalPemda/1.0 (reverse-geocode)", Accept: "application/json" },
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) return null;
    const j = (await res.json()) as {
      display_name?: string;
      address?: Record<string, string>;
    };
    const a = j.address ?? {};
    const parts = [
      a.road ?? a.pedestrian ?? a.neighbourhood,
      a.village ?? a.suburb ?? a.quarter,
      a.city_district ?? a.municipality,
      a.city ?? a.county ?? a.regency ?? a.town,
    ].filter((p, i, arr) => p && arr.indexOf(p) === i);
    const place = parts.length ? parts.join(", ") : (j.display_name ?? null);
    if (cache.size > 2000) cache.clear();
    cache.set(key, { at: Date.now(), place });
    return place;
  } catch {
    return null;
  }
}

export const reverseGeocode = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((i: unknown) =>
    z.object({ lat: z.number().min(-90).max(90), lng: z.number().min(-180).max(180) }).parse(i),
  )
  .handler(async ({ data }): Promise<Result> => {
    const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
    let kantor: string | null = null;
    let distance: number | null = null;
    const { data: rows } = await supabaseAdmin
      .from("kantor_qr")
      .select("lat,lng,radius_m,label,opd:opd_id(singkatan,nama)")
      .eq("aktif", true)
      .not("lat", "is", null);
    for (const r of (rows ?? []) as Array<{
      lat: number;
      lng: number;
      radius_m: number | null;
      label: string | null;
      opd: { singkatan: string; nama: string } | null;
    }>) {
      const d = haversine(data.lat, data.lng, Number(r.lat), Number(r.lng));
      if (d <= (r.radius_m ?? 100) && (distance === null || d < distance)) {
        distance = d;
        kantor = `${r.label || "Kantor"} ${r.opd?.singkatan ?? ""}`.trim();
      }
    }
    const place = await lookupPlace(data.lat, data.lng);
    return { place, kantor, distance_m: distance === null ? null : Math.round(distance) };
  });
