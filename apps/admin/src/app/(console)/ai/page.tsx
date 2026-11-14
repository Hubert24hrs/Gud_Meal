"use client";

import { formatDateTime } from "@gudmeal/api-client";
import { Badge, Card, DataTable, ErrorState, Skeleton, Stat } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { useAgentsApi } from "@/lib/api";

interface Metrics {
  runs: number; input_tokens: number; output_tokens: number; cost_usd: number; cost_per_run_usd: number; avg_latency_ms: number;
  by_status: Record<string, number>; by_agent: Record<string, number>; model: string;
  tools: Record<string, { calls: number; errors: number; avg_latency_ms: number }>;
}

export default function AiPage() {
  const agents = useAgentsApi();
  const m = useQuery({ queryKey: ["ai-metrics"], queryFn: () => agents.metrics(7) as Promise<unknown> as Promise<Metrics>, refetchInterval: 30_000 });
  const inv = useQuery({ queryKey: ["ai-invocations"], queryFn: () => agents.invocations(), refetchInterval: 30_000 });
  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-display text-3xl">AI agents</h1>
        <p className="text-sm text-muted">LangGraph orchestrator · last 7 days · model {m.data?.model ?? "…"}</p>
      </div>
      {m.isLoading ? <Skeleton className="h-28" /> : m.error || !m.data ? (
        <ErrorState message={(m.error as Error)?.message ?? "Agents service unavailable"} onRetry={() => m.refetch()} />
      ) : (
        <>
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <Stat label="Conversations turns" value={m.data.runs} hint={Object.entries(m.data.by_status).map(([k, v]) => `${k} ${v}`).join(" · ")} />
            <Stat label="Tokens" value={(m.data.input_tokens + m.data.output_tokens).toLocaleString()} hint={`${m.data.input_tokens.toLocaleString()} in · ${m.data.output_tokens.toLocaleString()} out`} />
            <Stat label="Model cost" value={`$${m.data.cost_usd.toFixed(4)}`} hint={`$${m.data.cost_per_run_usd.toFixed(5)} per turn`} />
            <Stat label="Avg latency" value={`${Math.round(m.data.avg_latency_ms)} ms`} />
          </div>
          <div className="grid gap-4 lg:grid-cols-2">
            <Card className="p-5">
              <h2 className="mb-3 font-semibold">Routing by specialist agent</h2>
              {Object.entries(m.data.by_agent).map(([agent, n]) => (
                <div key={agent} className="mb-2 flex items-center gap-3 text-sm">
                  <span className="w-24 capitalize">{agent}</span>
                  <div className="h-2 flex-1 rounded-full bg-surface-muted"><div className="h-2 rounded-full bg-secondary" style={{ width: `${(n / Math.max(1, m.data.runs)) * 100}%` }} /></div>
                  <span className="w-8 text-right tabular-nums">{n}</span>
                </div>
              ))}
            </Card>
            <Card className="p-5">
              <h2 className="mb-3 font-semibold">Tool reliability</h2>
              {Object.entries(m.data.tools).map(([tool, t]) => (
                <p key={tool} className="flex justify-between border-b border-border py-1 text-sm">
                  <span className="font-mono text-xs">{tool}</span>
                  <span>{t.calls} calls · {t.errors ? <Badge tone="danger">{t.errors} errors</Badge> : <Badge tone="success">0 errors</Badge>} · {Math.round(t.avg_latency_ms)} ms</span>
                </p>
              ))}
              {Object.keys(m.data.tools).length === 0 && <p className="text-sm text-muted">No tool calls yet.</p>}
            </Card>
          </div>
        </>
      )}
      <section className="space-y-2">
        <h2 className="font-semibold">Recent tool invocations</h2>
        <DataTable rows={(inv.data ?? []) as Record<string, unknown>[]} rowKey={(r) => `${r.thread_id}-${r.created_at}-${r.tool}`} empty="No invocations yet" columns={[
          { key: "t", header: "When", render: (r) => formatDateTime(String(r.created_at)) },
          { key: "tool", header: "Tool", render: (r) => <span className="font-mono text-xs">{String(r.tool)}</span> },
          { key: "s", header: "Result", render: (r) => <Badge tone={r.status === "ok" ? "success" : "danger"}>{String(r.status)}{r.error ? `: ${r.error}` : ""}</Badge> },
          { key: "m", header: "Mutating", render: (r) => (r.mutating ? "yes" : "") },
          { key: "l", header: "Latency", render: (r) => `${Math.round(Number(r.latency_ms))} ms` },
          { key: "u", header: "User", render: (r) => String(r.uid).slice(0, 10) },
        ]} />
      </section>
    </div>
  );
}
