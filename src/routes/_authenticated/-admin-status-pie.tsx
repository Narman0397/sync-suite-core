// Lazy chart: komposisi status admin dashboard.
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer } from "recharts";

type Row = { name: string; value: number; fill: string };

export default function AdminStatusPie({ data }: { data: Row[] }) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <PieChart>
        <Pie
          data={data}
          dataKey="value"
          nameKey="name"
          innerRadius={48}
          outerRadius={80}
          paddingAngle={2}
        >
          {data.map((e, i) => (
            <Cell key={i} fill={e.fill} />
          ))}
        </Pie>
        <Tooltip
          contentStyle={{
            background: "oklch(1 0 0)",
            border: "1px solid oklch(0.91 0.012 250)",
            borderRadius: 8,
            fontSize: 12,
          }}
        />
      </PieChart>
    </ResponsiveContainer>
  );
}