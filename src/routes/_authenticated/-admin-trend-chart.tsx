// Lazy chart: trend 14 hari admin dashboard. Prefix "-" agar bukan route.
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
} from "recharts";

type Row = { label: string; masuk: number; selesai: number };

export default function AdminTrendChart({ data }: { data: Row[] }) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <AreaChart data={data} margin={{ top: 5, right: 8, bottom: 0, left: -20 }}>
        <defs>
          <linearGradient id="gMasuk" x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%" stopColor="oklch(0.55 0.16 258)" stopOpacity={0.5} />
            <stop offset="100%" stopColor="oklch(0.55 0.16 258)" stopOpacity={0} />
          </linearGradient>
          <linearGradient id="gSelesai" x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%" stopColor="oklch(0.62 0.14 155)" stopOpacity={0.5} />
            <stop offset="100%" stopColor="oklch(0.62 0.14 155)" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="oklch(0.91 0.012 250)" />
        <XAxis dataKey="label" tick={{ fontSize: 11 }} />
        <YAxis allowDecimals={false} tick={{ fontSize: 11 }} />
        <Tooltip
          contentStyle={{
            background: "oklch(1 0 0)",
            border: "1px solid oklch(0.91 0.012 250)",
            borderRadius: 8,
            fontSize: 12,
          }}
        />
        <Area
          type="monotone"
          dataKey="masuk"
          name="Masuk"
          stroke="oklch(0.42 0.16 258)"
          fill="url(#gMasuk)"
          strokeWidth={2}
        />
        <Area
          type="monotone"
          dataKey="selesai"
          name="Selesai"
          stroke="oklch(0.62 0.14 155)"
          fill="url(#gSelesai)"
          strokeWidth={2}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}