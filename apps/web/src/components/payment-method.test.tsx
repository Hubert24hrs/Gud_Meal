import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { useState } from "react";
import { afterEach, describe, expect, it, vi } from "vitest";

const api = {
  wallet: { get: vi.fn() },
  orders: { summary: vi.fn() },
};
const publicConfig = vi.fn();
vi.mock("@/lib/api", () => ({ useApi: () => api, publicApi: { catalog: { publicConfig } } }));
vi.mock("next/link", () => ({ default: ({ href, children, ...rest }: { href: string; children: React.ReactNode }) => <a href={href} {...rest}>{children}</a> }));

const { PaymentMethodPicker, checkoutProvider, continueAfterCheckout } = await import("./payment-method");

function wallet(balance: number, enabled = true) {
  return { balance_kobo: balance, currency: "NGN", enabled, refund_to_wallet: false, transactions: [], seller: null,
    limits: { min_topup_kobo: 50_000, max_topup_kobo: 10_000_000, max_balance_kobo: 30_000_000 } };
}

function Harness({ total, cashOffered = true }: { total: number; cashOffered?: boolean }) {
  const [method, setMethod] = useState<"card" | "wallet" | "cash">("card");
  return (
    <>
      <PaymentMethodPicker totalKobo={total} value={method} onChange={setMethod} cash={{ offered: cashOffered }} />
      <output data-testid="method">{method}</output>
    </>
  );
}

function renderPicker(total: number, cashOffered = true) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(<QueryClientProvider client={qc}><Harness total={total} cashOffered={cashOffered} /></QueryClientProvider>);
}

describe("payment method picker", () => {
  afterEach(() => { cleanup(); vi.clearAllMocks(); });

  it("offers the wallet only when the balance covers the order, and says how much to top up", async () => {
    api.wallet.get.mockResolvedValue(wallet(500_000));
    api.orders.summary.mockResolvedValue({ completed_count: 2 });
    publicConfig.mockResolvedValue({ pay_on_delivery: { enabled: true, max_order_kobo: 2_500_000 } });
    renderPicker(750_000);
    const walletOption = await screen.findByRole("radio", { name: /GudMeals wallet/ });
    await waitFor(() => expect(walletOption.textContent).toContain("top up ₦2,500 more"));
    expect((walletOption as HTMLButtonElement).disabled).toBe(true);
    expect(screen.getByRole("link", { name: "Top up your wallet" }).getAttribute("href")).toBe("/wallet");

    const cash = screen.getByRole("radio", { name: /Pay on delivery/ });
    await waitFor(() => expect((cash as HTMLButtonElement).disabled).toBe(false));
    fireEvent.click(cash);
    expect(screen.getByTestId("method").textContent).toBe("cash");
  });

  it("selects the wallet when it can pay, and keeps pay on delivery locked before the first order", async () => {
    api.wallet.get.mockResolvedValue(wallet(2_000_000));
    api.orders.summary.mockResolvedValue({ completed_count: 0 });
    publicConfig.mockResolvedValue({ pay_on_delivery: { enabled: true, max_order_kobo: 2_500_000 } });
    renderPicker(750_000);
    const walletOption = await screen.findByRole("radio", { name: /GudMeals wallet/ });
    await waitFor(() => expect((walletOption as HTMLButtonElement).disabled).toBe(false));
    fireEvent.click(walletOption);
    expect(screen.getByTestId("method").textContent).toBe("wallet");
    const cash = screen.getByRole("radio", { name: /Pay on delivery/ });
    await waitFor(() => expect(cash.textContent).toContain("Unlocks after your first order"));
    expect((cash as HTMLButtonElement).disabled).toBe(true);
  });

  it("hides pay on delivery for packages and maps methods to checkout providers", async () => {
    api.wallet.get.mockResolvedValue(wallet(0));
    renderPicker(300_000, false);
    await screen.findByRole("radio", { name: /GudMeals wallet/ });
    expect(screen.queryByRole("radio", { name: /Pay on delivery/ })).toBeNull();
    expect(api.orders.summary).not.toHaveBeenCalled();
    expect([checkoutProvider("card"), checkoutProvider("wallet"), checkoutProvider("cash")]).toEqual([undefined, "wallet", "cash"]);

    const go = vi.fn();
    continueAfterCheckout({ order_id: "o1", status: "submitted_to_restaurant", provider: "cash", reference: "R", authorization_url: null, amount_kobo: 1 }, go);
    expect(go).toHaveBeenCalledWith("/orders/o1");
  });
});
