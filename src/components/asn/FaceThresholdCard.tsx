// Slider Super Admin untuk mengatur ambang pencocokan wajah absensi ASN.
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { Loader2, SlidersHorizontal } from "lucide-react";
import { Slider } from "@/components/ui/slider";
import { getFaceThresholdSetting, setFaceThresholdSetting } from "@/lib/asn-face.functions";

type Setting = { threshold: number; default: number; min: number; max: number };

function label(t: number) {
  if (t >= 0.86) return "Sangat ketat — keamanan tinggi, ASN lebih sering diminta ulang";
  if (t >= 0.8) return "Ketat";
  if (t >= 0.74) return "Seimbang (disarankan)";
  if (t >= 0.68) return "Longgar — lebih mudah lolos";
  return "Sangat longgar — risiko titip absen meningkat";
}

export function FaceThresholdCard() {
  const [s, setS] = useState<Setting | null>(null);
  const [val, setVal] = useState(0.78);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    (getFaceThresholdSetting() as unknown as Promise<Setting>)
      .then((r) => {
        setS(r);
        setVal(r.threshold);
      })
      .catch((e) => toast.error((e as Error).message));
  }, []);

  async function save() {
    setSaving(true);
    try {
      const r = (await setFaceThresholdSetting({ data: { threshold: val } })) as {
        threshold: number;
      };
      setS((p) => (p ? { ...p, threshold: r.threshold } : p));
      toast.success(`Ambang pencocokan wajah disimpan: ${Math.round(r.threshold * 100)}%`);
    } catch (e) {
      toast.error((e as Error).message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="mt-4 rounded-xl border border-border bg-card p-4">
      <div className="flex items-center gap-2 font-display text-sm font-bold">
        <SlidersHorizontal className="h-4 w-4 text-primary" /> Ambang Pencocokan Wajah
      </div>
      {!s ? (
        <div className="mt-3 flex items-center text-xs text-muted-foreground">
          <Loader2 className="mr-2 h-3.5 w-3.5 animate-spin" /> Memuat…
        </div>
      ) : (
        <>
          <div className="mt-3 flex items-baseline justify-between">
            <span className="font-display text-2xl font-bold">{Math.round(val * 100)}%</span>
            <span className="text-xs text-muted-foreground">
              Bawaan {Math.round(s.default * 100)}%
            </span>
          </div>
          <Slider
            className="mt-3"
            min={s.min}
            max={s.max}
            step={0.01}
            value={[val]}
            onValueChange={(v) => setVal(v[0])}
            aria-label="Ambang pencocokan wajah"
          />
          <div className="mt-1 flex justify-between text-[11px] text-muted-foreground">
            <span>Longgar {Math.round(s.min * 100)}%</span>
            <span>Ketat {Math.round(s.max * 100)}%</span>
          </div>
          <p className="mt-2 text-xs text-muted-foreground">{label(val)}</p>
          <div className="mt-3 flex gap-2">
            <button
              onClick={save}
              disabled={saving || val === s.threshold}
              className="inline-flex h-9 items-center rounded-md bg-gradient-primary px-4 text-xs font-semibold text-primary-foreground disabled:opacity-60"
            >
              {saving && <Loader2 className="mr-2 h-3.5 w-3.5 animate-spin" />} Simpan
            </button>
            <button
              onClick={() => setVal(s.default)}
              className="h-9 rounded-md border border-border px-3 text-xs"
            >
              Kembalikan bawaan
            </button>
          </div>
        </>
      )}
    </div>
  );
}
