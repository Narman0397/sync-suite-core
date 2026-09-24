import { createFileRoute, redirect } from "@tanstack/react-router";

export const Route = createFileRoute("/_authenticated/admin/eksekutif")({
  beforeLoad: () => {
    throw redirect({ to: "/executive", replace: true });
  },
});
