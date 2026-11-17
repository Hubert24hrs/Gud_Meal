import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

const auth = { user: null as null | { uid: string }, loading: false };
const verify = vi.fn();
vi.mock("@/lib/auth", () => ({ useAuth: () => auth }));
vi.mock("@/lib/api", () => ({ useApi: () => ({ payments: { verify } }) }));
vi.mock("next/navigation", () => ({
  useSearchParams: () => new URLSearchParams("order_id=o1&reference=GM-ABC123"),
}));
vi.mock("next/link", () => ({
  default: ({ href, children }: { href: string; children: React.ReactNode }) => <a href={href}>{children}</a>,
}));

const { default: CallbackPage } = await import("./page");

function show() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(<QueryClientProvider client={qc}><CallbackPage /></QueryClientProvider>);
}

afterEach(() => {
  cleanup();
  verify.mockReset();
});

describe("payment return page", () => {
  it("sends app payments (no website session) back to the app instead of asking to sign in", () => {
    auth.user = null;
    show();
    expect(screen.getByRole("heading", { name: "Return to the Gud Meal app" })).toBeTruthy();
    const signIn = screen.getByRole("link", { name: /Paid on the website\? Sign in/ });
    // Signing in on the website comes back here with the payment reference intact.
    expect(signIn.getAttribute("href")).toBe(
      `/login?next=${encodeURIComponent("/checkout/callback?order_id=o1&reference=GM-ABC123")}`,
    );
    expect(verify).not.toHaveBeenCalled();
  });

  it("verifies the payment for a signed-in website customer", async () => {
    auth.user = { uid: "cust-1" };
    verify.mockResolvedValue({ status: "succeeded", order_id: "o1", purpose: "order" });
    show();
    await waitFor(() => expect(screen.getByRole("heading", { name: "Payment confirmed" })).toBeTruthy());
    expect(verify).toHaveBeenCalledWith("GM-ABC123");
  });
});
