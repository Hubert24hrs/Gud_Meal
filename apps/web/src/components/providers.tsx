"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useState, type ReactNode } from "react";
import { AuthProvider } from "@/lib/auth";
import { CartProvider } from "@/lib/cart";
import { LocationProvider } from "@/lib/location";

export function Providers({ children }: { children: ReactNode }) {
  const [client] = useState(() => new QueryClient({
    defaultOptions: {
      queries: { staleTime: 30_000, retry: 1, refetchOnWindowFocus: false },
    },
  }));
  return (
    <QueryClientProvider client={client}>
      <AuthProvider>
        <LocationProvider>
          <CartProvider>{children}</CartProvider>
        </LocationProvider>
      </AuthProvider>
    </QueryClientProvider>
  );
}
