// Lazy charts untuk /kinerja-opd. Prefix "-" bukan route.
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
  LineChart,
  Line,
} from "recharts";

type TrendRow = { bulan: string; masuk: number; selesai: number; on_time: number };
type BarRow = { name: string; total: number };
type PieRow = { name: string; value: number; color: string };

export function KinerjaTrendChart({ data }: { data: TrendRow[] }) {
  return (
    <ResponsiveContainer>
      <LineChart data={data}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="bulan" />
        <YAxis />
        <Tooltip />
        <Legend />
        <Line type="monotone" dataKey="masuk" stroke="#3b82f6" name="Masuk" />
        <Line type="monotone" dataKey="selesai" stroke="#10b981" name="Selesai" />
        <Line type="monotone" dataKey="on_time" stroke="#f59e0b" name="Tepat Waktu" />
      </LineChart>
    </ResponsiveContainer>
  );
}

export function KinerjaBarChart({ data }: { data: BarRow[] }) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <BarChart data={data} layout="vertical" margin={{ left: 50, right: 20 }}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis type="number" />
        <YAxis type="category" dataKey="name" width={100} />
        <Tooltip />
        <Bar dataKey="total" fill="oklch(0.55 0.16 258)" name="Total Permohonan" />
      </BarChart>
    </ResponsiveContainer>
  );
}

export function KinerjaPieChart({ data }: { data: PieRow[] }) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <PieChart>
        <Pie data={data} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label>
          {data.map((entry, index) => (
            <Cell key={`cell-${index}`} fill={entry.color} />
          ))}
        </Pie>
        <Tooltip />
        <Legend />
      </PieChart>
    </ResponsiveContainer>
  );
}