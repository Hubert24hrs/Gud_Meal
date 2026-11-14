"use client";

import { Logo, cn } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { Bike, Bot, ClipboardCheck, Gauge, Landmark, LifeBuoy, ListOrdered, ReceiptText, ScrollText, Settings2, Store, Undo2 } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ReactNode } from "react";
import { Gate } from "@/components/gate";
import { useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";

const NAV = [
  ["/", "Overview", Gauge], ["/orders", "Orders", ListOrdered], ["/applications", "Verification", ClipboardCheck],
  ["/restaurants", "Restaurants", Store], ["/riders", "Riders", Bike], ["/refunds", "Refunds", Undo2],
  ["/payments", "Payments", ReceiptText], ["/finance", "Finance", Landmark], ["/support", "Support", LifeBuoy],
  ["/ai", "AI agents", Bot], ["/config", "Configuration", Settings2], ["/audit", "Audit log", ScrollText],
] as const;

export default function ConsoleLayout({ children }: { children: ReactNode }) {
  return <Gate><Shell>{children}</Shell></Gate>;
}

function Shell({ children }: { children: ReactNode }) {
  const path = usePathname();
  const api = useApi();
  const { signOut } = useAuth();
  const me = useQuery({ queryKey: ["me"], queryFn: () => api.me.get() });
  const isStaff = me.data?.permissions.length;

  return (
    <div className="grid min-h-dvh lg:grid-cols-[232px_1fr]">
      <aside className="border-b border-border bg-text text-background lg:border-b-0">
        <div className="flex items-center justify-between p-4">
          <span className="[&_*]:text-background"><Logo /></span>
        </div>
        <nav className="flex gap-1 overflow-x-auto px-2 pb-3 lg:flex-col" aria-label="Command Centre">
          {NAV.map(([href, label, Icon]) => {
            const active = href === "/" ? path === "/" : path.startsWith(href);
            return (
              <Link key={href} href={href} aria-current={active ? "page" : undefined}
                className={cn("flex shrink-0 items-center gap-2 rounded-md px-3 py-2 text-sm font-medium",
                  active ? "bg-primary text-on-primary" : "text-background/70 hover:bg-white/10 hover:text-background")}>
                <Icon className="size-4" aria-hidden="true" /> {label}
              </Link>
            );
          })}
        </nav>
        <div className="hidden px-4 pb-4 text-xs text-background/60 lg:block">
          <p className="truncate">{me.data?.email}</p>
          <p>{me.data?.roles.filter((r) => r !== "customer").join(", ")}</p>
          <button className="mt-2 font-semibold text-accent" onClick={() => signOut()}>Sign out</button>
        </div>
      </aside>
      <main className="min-w-0 p-4 sm:p-6">
        {me.data && !isStaff ? (
          <p role="alert" className="rounded-md bg-accent-soft p-4 text-sm">This account has no Command Centre permissions. Ask a super admin to assign a staff role.</p>
        ) : children}
      </main>
    </div>
  );
}
