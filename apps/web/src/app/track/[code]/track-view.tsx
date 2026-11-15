"use client";

import { ApiError } from "@gudmeal/api-client";
import { Card, ErrorState, Skeleton } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { WaybillTimeline } from "@/components/waybill-timeline";
import { publicApi } from "@/lib/api";
import { TrackForm } from "../track-form";

export function TrackView({ code }: { code: string }) {
  const tracking = useQuery({
    queryKey: ["track", code],
    queryFn: () => publicApi.waybills.track(code),
    retry: (count, error) => !(error instanceof ApiError && error.status === 404) && count < 2,
    refetchInterval: (q) => (q.state.data && !q.state.data.delivered && q.state.data.label !== "Cancelled" ? 30_000 : false),
  });
  if (tracking.isLoading) return <Skeleton className="h-64" />;
  if (tracking.error || !tracking.data) {
    const notFound = tracking.error instanceof ApiError && tracking.error.status === 404;
    return (
      <div className="space-y-4">
        <ErrorState message={notFound ? `We couldn't find tracking number ${code}. Check it with the sender.` : "Tracking is unavailable right now. Please try again."} />
        <TrackForm initial={code} />
      </div>
    );
  }
  return (
    <Card className="p-5">
      <WaybillTimeline data={tracking.data} />
    </Card>
  );
}
