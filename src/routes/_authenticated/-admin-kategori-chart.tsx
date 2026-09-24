// Lazy chart: distribusi kategori admin dashboard.
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
} from "recharts";

type Row = { nama: string; jumlah: number };

export default function AdminKategoriChart({ data }: { data: Row[] }) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <BarChart data={data} layout="vertical" margin={{ left: 0, right: 8 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="oklch(0.91 0.012 250)" horizontal={false} />
        <XAxis type="number" allowDecimals={false} tick={{ fontSize: 11 }} />
        <YAxis type="category" dataKey="nama" width={110} tick={{ fontSize: 11 }} />
        <Tooltip
          contentStyle={{
            background: "oklch(1 0 0)",
            border: "1px solid oklch(0.91 0.012 250)",
            borderRadius: 8,
            fontSize: 12,
          }}
        />
        <Bar dataKey="jumlah" fill="oklch(0.55 0.16 258)" radius={[0, 6, 6, 0]} />
      </BarChart>
    </ResponsiveContainer>
  );
}