// Banner ringkas untuk Super Admin baru. Dapat di-dismiss permanen via localStorage.
import { useEffect, useState } from "react";
import { Info, X } from "lucide-react";
import { Button } from "@/components/ui/button";

const KEY = "admin_dashboard_hint_dismissed_v1";

export function OnboardingHint() {
  const [show, setShow] = useState(false);
  useEffect(() => {
    if (typeof window === "undefined") return;
    setShow(window.localStorage.getItem(KEY) !== "1");
  }, []);
  if (!show) return null;
  return (
    <div className="flex items-start gap-3 border-l-2 border-primary bg-primary-soft px-4 py-3 text-sm">
      <Info className="mt-0.5 h-4 w-4 shrink-0 text-primary" />
      <div className="flex-1">
        <div className="font-semibold text-foreground">Selamat datang di Command Center</div>
        <p className="text-xs text-muted-foreground">
          Gunakan status operasional untuk menemukan gangguan, lalu buka antrean prioritas atau
          salah satu dari lima ekosistem pemerintahan.
        </p>
      </div>
      <Button
        type="button"
        variant="ghost"
        size="icon"
        onClick={() => {
          window.localStorage.setItem(KEY, "1");
          setShow(false);
        }}
        aria-label="Sembunyikan tip"
        className="h-7 w-7 text-muted-foreground"
      >
        <X className="h-4 w-4" />
      </Button>
    </div>
  );
}
