// Chart section untuk /data — dipisah agar recharts (~360 KB) lazy-loaded.
// Prefix "-" mencegah TanStack Router memperlakukan file ini sebagai route.
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  Legend,
} from "recharts";

const PIE_COLORS = [
  "oklch(0.42 0.16 258)",
  "oklch(0.62 0.16 235)",
  "oklch(0.78 0.13 80)",
  "oklch(0.62 0.14 155)",
];

type LayananPoint = { bulan: string; permohonan: number; selesai: number };
type PendudukPoint = { name: string; value: number };
type AnggaranPoint = { sektor: string; nilai: number };

export default function DataCharts({
  layananBulanan,
  penduduk,
  anggaran,
}: {
  layananBulanan: LayananPoint[];
  penduduk: PendudukPoint[];
  anggaran: AnggaranPoint[];
}) {
  return (
    <section className="container-page mt-10 grid gap-6 lg:grid-cols-3">
      {layananBulanan.length > 0 && (
        <div className="rounded-2xl border border-border bg-card p-6 shadow-soft lg:col-span-2">
          <h3 className="font-semibold">Permohonan Layanan Publik</h3>
          <p className="text-sm text-muted-foreground">
            {layananBulanan.length} periode terakhir
          </p>
          <div className="mt-6 h-72">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={layananBulanan}>
                <defs>
                  <linearGradient id="g1" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="oklch(0.42 0.16 258)" stopOpacity={0.4} />
                    <stop offset="100%" stopColor="oklch(0.42 0.16 258)" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="g2" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="oklch(0.62 0.16 235)" stopOpacity={0.4} />
                    <stop offset="100%" stopColor="oklch(0.62 0.16 235)" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="oklch(0.91 0.012 250)" />
                <XAxis dataKey="bulan" stroke="oklch(0.48 0.03 255)" fontSize={12} />
                <YAxis stroke="oklch(0.48 0.03 255)" fontSize={12} />
                <Tooltip
                  contentStyle={{ borderRadius: 12, border: "1px solid oklch(0.91 0.012 250)" }}
                />
                <Area
                  type="monotone"
                  dataKey="permohonan"
                  stroke="oklch(0.42 0.16 258)"
                  fill="url(#g1)"
                  strokeWidth={2}
                />
                <Area
                  type="monotone"
                  dataKey="selesai"
                  stroke="oklch(0.62 0.16 235)"
                  fill="url(#g2)"
                  strokeWidth={2}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      {penduduk.length > 0 && (
        <div className="rounded-2xl border border-border bg-card p-6 shadow-soft">
          <h3 className="font-semibold">Komposisi Penduduk</h3>
          <p className="text-sm text-muted-foreground">Berdasarkan kelompok usia</p>
          <div className="mt-2 h-72">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={penduduk}
                  dataKey="value"
                  nameKey="name"
                  innerRadius={55}
                  outerRadius={90}
                  paddingAngle={3}
                >
                  {penduduk.map((_, i) => (
                    <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend wrapperStyle={{ fontSize: 12 }} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      {anggaran.length > 0 && (
        <div className="rounded-2xl border border-border bg-card p-6 shadow-soft lg:col-span-3">
          <h3 className="font-semibold">Alokasi Anggaran per Sektor</h3>
          <p className="text-sm text-muted-foreground">
            Dalam miliar rupiah, tahun anggaran berjalan
          </p>
          <div className="mt-6 h-80">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={anggaran}>
                <CartesianGrid strokeDasharray="3 3" stroke="oklch(0.91 0.012 250)" />
                <XAxis dataKey="sektor" stroke="oklch(0.48 0.03 255)" fontSize={12} />
                <YAxis stroke="oklch(0.48 0.03 255)" fontSize={12} />
                <Tooltip
                  contentStyle={{ borderRadius: 12, border: "1px solid oklch(0.91 0.012 250)" }}
                />
                <Bar dataKey="nilai" fill="oklch(0.42 0.16 258)" radius={[8, 8, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}
    </section>
  );
}