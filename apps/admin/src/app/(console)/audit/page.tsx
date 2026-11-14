"use client";

import { formatDateTime } from "@gudmeal/api-client";
import { DataTable, ErrorState, Input, Skeleton } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { useDeferredValue, useState } from "react";
import { useApi } from "@/lib/api";

export default function AuditPage() {
  const api = useApi();
  const [resource, setResource] = useState("");
  const query = useDeferredValue(resource.trim());
  const list = useQuery({ queryKey: ["audit", query], queryFn: () => api.admin.audit(query ? { resource_id: query } : {}) });
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-3xl">Audit log</h1>
        <label className="w-72"><span className="sr-only">Filter by resource id</span>
          <Input value={resource} onChange={(e) => setResource(e.target.value)} placeholder="Filter by order / refund / user id" /></label>
      </div>
      <p className="text-sm text-muted">Append-only: the database rejects edits and deletions of audit records.</p>
      {list.isLoading ? <Skeleton className="h-96" /> : list.error ? <ErrorState message={(list.error as Error).message} /> : (
        <DataTable rows={list.data ?? []} rowKey={(e) => e.id} empty="No audit events" columns={[
          { key: "t", header: "When", render: (e) => formatDateTime(e.occurred_at) },
          { key: "a", header: "Action", render: (e) => <span className="font-mono text-xs">{e.action}</span> },
          { key: "r", header: "Resource", render: (e) => `${e.resource_type}/${e.resource_id.slice(0, 12)}` },
          { key: "who", header: "Actor", render: (e) => `${e.actor_id.slice(0, 12)} ${e.actor_roles.filter((r) => r !== "customer").join(",")}` },
          { key: "d", header: "Details", render: (e) => <code className="line-clamp-2 max-w-md text-xs">{JSON.stringify(e.details)}</code> },
        ]} />
      )}
    </div>
  );
}
