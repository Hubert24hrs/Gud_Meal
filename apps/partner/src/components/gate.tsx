"use client";

import { Skeleton } from "@gudmeal/ui";
import { useRouter } from "next/navigation";
import { useEffect, type ReactNode } from "react";
import { useAuth } from "@/lib/auth";

/** Redirects to /login when signed out. Authorisation itself is enforced by the API on every call. */
export function Gate({ children }: { children: ReactNode }) {
  const { user, loading } = useAuth();
  const router = useRouter();
  useEffect(() => {
    if (!loading && !user) router.replace("/login");
  }, [loading, user, router]);
  if (loading || !user) return <div className="space-y-3 p-8"><Skeleton className="h-10 w-1/3" /><Skeleton className="h-64" /></div>;
  return <>{children}</>;
}
