import { useCallback, useEffect, useState } from "react";
import { listBiometricCredentials } from "@/lib/asn-biometric.functions";

type Device = {
  id: string;
  device_label: string | null;
  finger_label: string | null;
  created_at: string;
  last_used_at: string | null;
};

export function useBiometricStatus() {
  const [devices, setDevices] = useState<Device[]>([]);
  const [min, setMin] = useState(3);
  const [loading, setLoading] = useState(true);

  const reload = useCallback(async () => {
    try {
      const r = (await listBiometricCredentials()) as unknown as { rows: Device[]; min: number };
      setDevices(r.rows ?? []);
      setMin(r.min ?? 3);
    } catch {
      setDevices([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void reload();
  }, [reload]);

  return { devices, min, enrolled: devices.length >= min, loading, reload };
}

/** Kartu status sidik jari untuk ASN (pendaftaran dilakukan oleh Admin OPD / Super Admin). */
export function BiometricEnrollCard({
  devices,
  min = 3,
  loading,
}: {
  devices: Device[];
  min?: number;
  loading: boolean;
  onChanged?: () => void | Promise<void>;
}) {
  if (loading) return null;
  const count = devices.length;
  if (count < min)
    return (
      <div className="mt-4 rounded-lg border border-border bg-surface p-3">
        <div className="text-sm font-semibold">
          Sidik jari belum lengkap ({count}/{min} jari)
        </div>
        <p className="mt-0.5 text-xs text-muted-foreground">
          Perekaman sidik jari dilakukan oleh Admin OPD atau Super Admin. Temui admin OPD Anda untuk
          merekam minimal {min} jari. Sementara itu absensi memakai QR kantor, GPS, dan foto wajah.
        </p>
      </div>
    );
  return (
    <div className="mt-4 rounded-lg border border-success/40 bg-success/10 p-3">
      <div className="text-sm font-semibold text-success">
        Verifikasi sidik jari aktif ({count} jari terdaftar)
      </div>
      <p className="mt-0.5 text-xs text-muted-foreground">
        Setiap absen wajib dikonfirmasi dengan sidik jari yang direkam admin.
      </p>
      <ul className="mt-2 space-y-0.5 text-xs text-muted-foreground">
        {devices.map((d) => (
          <li key={d.id}>
            {d.finger_label ?? "Jari"} · {d.device_label ?? "Perangkat"} ·{" "}
            {new Date(d.created_at).toLocaleDateString("id-ID")}
          </li>
        ))}
      </ul>
    </div>
  );
}
