export function DashboardLoadingState() {
  return (
    <div aria-label="Memuat ringkasan dashboard" aria-busy="true" className="space-y-6">
      <div className="rounded-lg border border-border bg-card p-4 shadow-soft">
        <div className="skeleton-shimmer h-4 w-40 rounded" />
        <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
          {[0, 1, 2, 3].map((item) => (
            <div key={item} className="skeleton-shimmer h-14 rounded-md" />
          ))}
        </div>
      </div>
      <div className="skeleton-shimmer h-52 rounded-lg" />
      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {[0, 1, 2, 3].map((item) => (
          <div key={item} className="skeleton-shimmer h-36 rounded-lg" />
        ))}
      </div>
      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-6 2xl:grid-cols-5">
        {[0, 1, 2, 3, 4].map((item) => (
          <div
            key={item}
            className={`skeleton-shimmer h-72 rounded-lg ${
              item === 0
                ? "xl:col-span-2 2xl:col-span-1"
                : item < 3
                  ? "xl:col-span-2 2xl:col-span-1"
                  : "xl:col-span-3 2xl:col-span-1"
            }`}
          />
        ))}
      </div>
    </div>
  );
}