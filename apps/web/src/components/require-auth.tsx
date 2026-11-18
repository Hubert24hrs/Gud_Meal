"use client";

import { Button, Skeleton } from "@gudmeal/ui";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ReactNode } from "react";
import { useAuth } from "@/lib/auth";

export function RequireAuth({ children, reason }: { children: ReactNode; reason?: string }) {
  const { user, loading } = useAuth();
  const path = usePathname();
  if (loading) return <div className="container-page space-y-3 py-10"><Skeleton className="h-10 w-1/3" /><Skeleton className="h-40" /></div>;
  if (!user) {
    return (
      <div className="container-page flex flex-col items-center gap-4 py-20 text-center">
        <h1 className="font-display text-3xl">Sign in to continue</h1>
        <p className="max-w-md text-muted">{reason ?? "You need a GudMeals account for this."}</p>
        <Link href={`/login?next=${encodeURIComponent(path)}`}><Button size="lg">Sign in or create account</Button></Link>
      </div>
    );
  }
  return <>{children}</>;
}
