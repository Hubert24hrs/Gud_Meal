"use client";

import { Logo, Toggle, cn } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { BarChart3, ClipboardList, Settings, UtensilsCrossed, Wallet } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { use, type ReactNode } from "react";
import { Gate } from "@/components/gate";
import { useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";

const NAV = [
  ["orders", "Orders", ClipboardList], ["menu", "Menu", UtensilsCrossed], ["insights", "Insights", BarChart3],
  ["payouts", "Payouts", Wallet], ["settings", "Settings", Settings],
] as const;

export default function RestaurantLayout({ children, params }: { children: ReactNode; params: Promise<{ rid: string }> }) {
  const { rid } = use(params);
  return <Gate><Shell rid={rid}>{children}</Shell></Gate>;
}

function Shell({ rid, children }: { rid: string; children: ReactNode }) {
  const api = useApi();
  const qc = useQueryClient();
  const path = usePathname();
  const { user, signOut } = useAuth();
  const menu = useQuery({ queryKey: ["menu", rid], queryFn: () => api.partner.menu(rid) });
  const accepting = useMutation({
    mutationFn: (v: boolean) => api.partner.setAccepting(rid, v),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["menu", rid] }),
  });
  const r = menu.data?.restaurant;

  return (
    // Mobile: header row sized to content (auto) so short pages don't stretch it; min-w-0 lets the nav scroll
    // instead of widening the page.
    <div className="grid min-h-dvh grid-cols-1 grid-rows-[auto_1fr] lg:grid-cols-[240px_1fr] lg:grid-rows-1">
      <aside className="min-w-0 border-b border-border bg-surface lg:border-b-0 lg:border-r">
        <div className="flex items-center justify-between p-4 lg:block lg:space-y-4">
          <Logo />
          <p className="hidden text-xs font-semibold uppercase tracking-wide text-secondary lg:block">Partner</p>
        </div>
        <nav className="flex gap-1 overflow-x-auto px-2 pb-2 lg:flex-col lg:px-3" aria-label="Restaurant">
          {NAV.map(([slug, label, Icon]) => {
            const href = `/r/${rid}/${slug}`;
            const active = path.startsWith(href);
            return (
              <Link key={slug} href={href} aria-current={active ? "page" : undefined}
                className={cn("flex shrink-0 items-center gap-2 rounded-md px-3 py-2 text-sm font-semibold",
                  active ? "bg-primary-soft text-primary-strong" : "text-muted hover:bg-surface-muted hover:text-text")}>
                <Icon className="size-4" aria-hidden="true" /> {label}
              </Link>
            );
          })}
        </nav>
        <div className="hidden space-y-2 border-t border-border p-4 text-xs text-muted lg:block">
          <p className="truncate">{user?.email}</p>
          <button className="font-semibold text-primary" onClick={() => signOut()}>Sign out</button>
        </div>
      </aside>
      <div className="min-w-0">
        <header className="flex flex-wrap items-center justify-between gap-3 border-b border-border bg-background px-4 py-3 sm:px-6">
          <div>
            <h1 className="font-display text-xl">{r?.name ?? "…"}</h1>
            <p className="text-xs text-muted">{r?.area}</p>
          </div>
          {r && <Toggle checked={r.is_accepting_orders} disabled={accepting.isPending} onChange={(v) => accepting.mutate(v)}
            label={r.is_accepting_orders ? "Accepting orders" : "Paused"} />}
        </header>
        <div className="p-4 sm:p-6">{children}</div>
      </div>
    </div>
  );
}
