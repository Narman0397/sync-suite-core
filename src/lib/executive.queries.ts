import { queryOptions } from "@tanstack/react-query";
import { getExecutiveOpdScores, getExecutiveSummary } from "@/lib/executive.functions";

export const executiveSummaryQueryOptions = () =>
  queryOptions({
    queryKey: ["executive", "summary"],
    queryFn: () => getExecutiveSummary(),
    staleTime: 60_000,
    refetchInterval: 60_000,
    refetchIntervalInBackground: false,
  });

export const executiveOpdQueryOptions = () =>
  queryOptions({
    queryKey: ["executive", "opd-scores"],
    queryFn: () => getExecutiveOpdScores().then((result) => result.rows),
    staleTime: 60_000,
    refetchInterval: 60_000,
    refetchIntervalInBackground: false,
  });