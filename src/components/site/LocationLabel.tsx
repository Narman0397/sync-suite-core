// Menampilkan nama lokasi + kantor OPD terdekat untuk koordinat; fallback ke angka Lat/Long.
import { useEffect, useState } from "react";
import { reverseGeocode } from "@/lib/geocode.functions";

type Res = { place: string | null; kantor: string | null; distance_m: number | null };
const memo = new Map<string, Promise<Res | null>>();

function fetchPlace(lat: number, lng: number) {
  const key = `${lat.toFixed(4)},${lng.toFixed(4)}`;
  let p = memo.get(key);
  if (!p) {
    p = (reverseGeocode({ data: { lat, lng } }) as Promise<Res>).catch(() => {
      memo.delete(key);
      return null;
    });
    memo.set(key, p);
  }
  return p;
}

export function LocationLabel({
  lat,
  lng,
  prefix,
}: {
  lat: number | string | null | undefined;
  lng: number | string | null | undefined;
  prefix?: string;
}) {
  const la = lat === null || lat === undefined ? NaN : Number(lat);
  const ln = lng === null || lng === undefined ? NaN : Number(lng);
  const [res, setRes] = useState<Res | null>(null);
  useEffect(() => {
    if (Number.isNaN(la) || Number.isNaN(ln)) return;
    let alive = true;
    const t = setTimeout(() => {
      fetchPlace(la, ln).then((r) => alive && setRes(r));
    }, 400);
    return () => {
      alive = false;
      clearTimeout(t);
    };
  }, [la.toFixed?.(4), ln.toFixed?.(4)]); // eslint-disable-line react-hooks/exhaustive-deps
  if (Number.isNaN(la) || Number.isNaN(ln)) return <span>-</span>;
  const coord = `${la.toFixed(5)}, ${ln.toFixed(5)}`;
  return (
    <span>
      {prefix}
      {res?.kantor && <b className="text-success">{res.kantor} · </b>}
      {res?.place ? (
        <>
          {res.place} <span className="opacity-70">({coord})</span>
        </>
      ) : (
        coord
      )}
    </span>
  );
}
