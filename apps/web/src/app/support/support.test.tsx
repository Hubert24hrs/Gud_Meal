import type { SupportContacts } from "@gudmeal/api-client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

let support: SupportContacts;
vi.mock("@/lib/auth", () => ({ useAuth: () => ({ user: null, loading: false }) }));
vi.mock("@/lib/api", () => ({
  publicApi: { catalog: { publicConfig: async () => ({ support }) } },
  useApi: () => ({}),
}));
vi.mock("next/link", () => ({
  default: ({ href, children, className }: { href: string; children: React.ReactNode; className?: string }) => (
    <a href={href} className={className}>{children}</a>
  ),
}));

const { default: SupportPage } = await import("./page");

function show() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(<QueryClientProvider client={qc}><SupportPage /></QueryClientProvider>);
}

afterEach(cleanup);

describe("support page", () => {
  it("offers the real customer-care email while WhatsApp and phone are still coming soon", async () => {
    support = { whatsapp: "", phone: "", email: "customercare@yummy247.com", hours: "Every day, 8am to 10pm", placeholders: true };
    show();
    const email = await screen.findByRole("link", { name: /customercare@yummy247\.com/ });
    expect(email.getAttribute("href")).toBe("mailto:customercare@yummy247.com");
    expect(screen.getAllByText("Coming soon. Use Yummy or open a ticket for now.")).toHaveLength(2);
    expect(screen.queryByRole("link", { name: /WhatsApp/ })).toBeNull();
    expect(screen.queryByRole("link", { name: /Call us/ })).toBeNull();
  });

  it("links every contact once all three exist", async () => {
    support = { whatsapp: "+234 812 345 6789", phone: "+234 1 234 5678", email: "customercare@yummy247.com", hours: "", placeholders: false };
    show();
    expect((await screen.findByRole("link", { name: /WhatsApp/ })).getAttribute("href")).toBe("https://wa.me/2348123456789");
    expect(screen.getByRole("link", { name: /Call us/ }).getAttribute("href")).toBe("tel:+23412345678");
    expect(screen.queryByText("Coming soon. Use Yummy or open a ticket for now.")).toBeNull();
  });
});
