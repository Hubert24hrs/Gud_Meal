"use client";

import { Button, EmptyState, Skeleton } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { Gate } from "@/components/gate";
import { useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";

export default function Home() {
  return <Gate><Pick /></Gate>;
}

function Pick() {
  const api = useApi();
  const router = useRouter();
  const { signOut } = useAuth();
  const mine = useQuery({ queryKey: ["my-restaurants"], queryFn: () => api.partner.restaurants() });
  useEffect(() => {
    if (mine.data?.length === 1) router.replace(`/r/${mine.data[0]!.restaurant.id}/orders`);
  }, [mine.data, router]);
  if (mine.isLoading || mine.data?.length === 1) return <div className="p-8"><Skeleton className="h-40" /></div>;
  if (!mine.data?.length) {
    return (
      <div className="mx-auto max-w-lg p-8">
        <EmptyState title="No restaurant linked to this account" body="Ask your restaurant owner to add you, or apply as a new partner."
          action={<Button variant="outline" onClick={() => signOut()}>Sign out</Button>} />
      </div>
    );
  }
  return (
    <div className="mx-auto max-w-lg space-y-3 p-8">
      <h1 className="font-display text-2xl">Choose a restaurant</h1>
      {mine.data.map(({ restaurant, role }) => (
        <button key={restaurant.id} onClick={() => router.push(`/r/${restaurant.id}/orders`)}
          className="flex w-full items-center justify-between rounded-lg border border-border bg-surface p-4 text-left hover:border-primary">
          <span className="font-semibold">{restaurant.name}</span><span className="text-sm capitalize text-muted">{role}</span>
        </button>
      ))}
    </div>
  );
}
