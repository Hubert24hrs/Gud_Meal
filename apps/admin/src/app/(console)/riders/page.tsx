"use client";

import { formatDateTime } from "@gudmeal/api-client";
import { Badge, Button, DataTable, ErrorState, Skeleton } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useApi } from "@/lib/api";
import { LiveRidersMap } from "./live-map";

export default function RidersPage() {
  const api = useApi();
  const qc = useQueryClient();
  const list = useQuery({ queryKey: ["riders"], queryFn: () => api.admin.riders(), refetchInterval: 20_000 });
  const setStatus = useMutation({
    mutationFn: ({ uid, status }: { uid: string; status: string }) => {
      const reason = window.prompt(`Reason for setting ${status}?`) ?? "";
      if (reason.trim().length < 3) throw new Error("A reason of at least 3 characters is required");
      return api.admin.setRiderStatus(uid, status, reason);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["riders"] }),
  });
  return (
    <div className="space-y-4">
      <h1 className="font-display text-3xl">Riders</h1>
      <LiveRidersMap />
      {setStatus.error && <ErrorState message={(setStatus.error as Error).message} />}
      {list.isLoading ? <Skeleton className="h-96" /> : list.error ? <ErrorState message={(list.error as Error).message} /> : (
        <DataTable rows={list.data ?? []} rowKey={(r) => r.uid} columns={[
          { key: "name", header: "Rider", render: (r) => <span className="font-semibold">{r.name}</span> },
          { key: "vehicle", header: "Vehicle", render: (r) => r.vehicle },
          { key: "online", header: "Availability", render: (r) => (r.is_online ? <Badge tone="success">Online</Badge> : <Badge>Offline</Badge>) },
          { key: "load", header: "Active", render: (r) => r.active_order_ids.length },
          { key: "done", header: "Completed", render: (r) => r.completed_deliveries },
          { key: "rating", header: "Rating", render: (r) => r.rating.toFixed(2) },
          { key: "acc", header: "Acceptance", render: (r) => `${Math.round(r.acceptance_rate * 100)}%` },
          { key: "seen", header: "Last location", render: (r) => formatDateTime(r.last_location_at) },
          { key: "status", header: "Status", render: (r) => <Badge tone={r.status === "active" ? "success" : r.status === "suspended" ? "danger" : "warning"}>{r.status}</Badge> },
          { key: "actions", header: "", render: (r) => r.status === "active"
            ? <Button size="sm" variant="outline" onClick={() => setStatus.mutate({ uid: r.uid, status: "suspended" })}>Suspend</Button>
            : <Button size="sm" onClick={() => setStatus.mutate({ uid: r.uid, status: "active" })}>Activate</Button> },
        ]} />
      )}
    </div>
  );
}
