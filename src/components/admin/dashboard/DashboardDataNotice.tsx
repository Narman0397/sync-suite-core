import { AlertCircle } from "lucide-react";

export function DashboardDataNotice({ message }: { message: string }) {
  return (
    <div role="status" className="flex items-center gap-2 border-l-2 border-gold bg-gold/10 px-3 py-2 text-xs text-foreground">
      <AlertCircle className="h-4 w-4 shrink-0 text-gold-foreground" />
      <span>{message}</span>
    </div>
  );
}