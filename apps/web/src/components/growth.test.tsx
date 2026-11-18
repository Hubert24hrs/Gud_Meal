import type { GroupOrder, PlusOverview, RewardsOverview } from "@gudmeal/api-client";
import { cleanup, fireEvent, render, screen, within } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

vi.mock("next/navigation", () => ({
  useRouter: () => ({ push: vi.fn(), back: vi.fn(), replace: vi.fn() }),
  usePathname: () => "/",
  useSearchParams: () => new URLSearchParams(),
}));

const { GroupBill, GroupItems, groupStatusLabel, PlusSummary, RewardsSummary } = await import("./growth");
const { routeForScreen } = await import("@/app/assistant/chat");

const plan = {
  enabled: true, price_kobo: 150_000, vat_kobo: 10_465, period_days: 30, free_delivery_min_subtotal_kobo: 300_000,
  service_fee_discount_bps: 5_000, points_multiplier: 2, verticals: ["food", "beauty"],
  benefits: ["Free delivery on Food and Beauty orders of ₦3,000 or more", "50% off the service fee on Food and Beauty orders"],
};

const rewards: RewardsOverview = {
  points: 1_240, lifetime_points: 1_740, points_value_kobo: 124_000,
  redeem: { enabled: true, step_points: 500, step_value_kobo: 50_000, redeemable_points: 1_000, points_to_next: 0, min_subtotal_kobo: 200_000, valid_days: 90 },
  earn: { points_per_100_naira: 1, plus_multiplier: 2, member: true },
  referral: {
    enabled: true, code: "ADAO7K2P", friend_gets_kobo: 100_000, you_get_kobo: 100_000, min_subtotal_kobo: 300_000,
    friends_rewarded: 2, applied: false, can_apply: false, share_text: "Get ₦1,000 off with ADAO7K2P",
  },
  vouchers: [{ code: "GMP-3K7P9Q", description: "500 Gud points", value_kobo: 50_000, min_subtotal_kobo: 200_000, ends_at: null, source: "points" }],
  history: [{ id: "order:o1", kind: "earned", points: 130, order_id: "o1", voucher_code: null, note: "", at: "2026-11-15T12:00:00Z" }],
};

const group: GroupOrder = {
  id: "g1", code: "AB3K7P", status: "ordered", split_mode: "each", is_host: false, host_name: "Ada",
  restaurant: { id: "r-jollof-junction", name: "Jollof Junction" }, vertical: "food", fulfillment: "delivery", delivery_area: "Lekki Phase 1",
  members: [
    { uid: "cust-1", name: "Ada", is_host: true, me: false, ready: true, items: 1, items_kobo: 550_000 },
    { uid: "cust-2", name: "Bayo", is_host: false, me: true, ready: true, items: 2, items_kobo: 300_000 },
    { uid: "cust-3", name: "Chika", is_host: false, me: false, ready: false, items: 3, items_kobo: 1_100_000 },
  ],
  max_members: 10,
  lines: [
    { id: "l1", member_uid: "cust-2", member: "Bayo", item_id: "drink", name: "Chapman", quantity: 2, selections: [], options: [], notes: null, line_total_kobo: 300_000, problem: null },
    { id: "l2", member_uid: "cust-3", member: "Chika", item_id: "jollof", name: "Party Jollof", quantity: 1, selections: [], options: ["Protein: Chicken"], notes: null, line_total_kobo: 0, problem: "Chicken is unavailable" },
  ],
  estimated_items_kobo: 1_950_000, expires_at: "2026-11-15T15:00:00Z",
  order: { id: "o1", short_code: "GM12AB", status: "pending_payment", total_kobo: 2_400_000, breakdown: { subtotal_kobo: 1_950_000, delivery_fee_kobo: 150_000, service_fee_kobo: 97_500, small_order_fee_kobo: 0, vat_kobo: 18_563, discount_kobo: 0, total_kobo: 2_400_000, discount_funded_by: null, voucher_code: null } },
  total_kobo: 2_400_000,
  shares: [
    { uid: "cust-1", name: "Ada", me: false, items_kobo: 550_000, amount_kobo: 676_923, status: "unpaid", paid_by_host: false },
    { uid: "cust-2", name: "Bayo", me: true, items_kobo: 300_000, amount_kobo: 369_231, status: "paid", paid_by_host: false },
    { uid: "cust-3", name: "Chika", me: false, items_kobo: 1_100_000, amount_kobo: 1_353_846, status: "paid", paid_by_host: true },
  ],
  my_share: { amount_kobo: 369_231, items_kobo: 300_000, status: "paid" },
  paid_kobo: 1_723_077, remaining_kobo: 676_923, pay_by: "2026-11-15T13:30:00Z", can_pay: false, can_cover_rest: false, cancel_reason: null,
};

describe("GudMeals Plus, rewards and group orders", () => {
  afterEach(cleanup);

  it("shows the Plus price and benefits, and the member's status", () => {
    const join: PlusOverview = { plan, member: false, membership: null };
    render(<PlusSummary data={join} />);
    expect(screen.getByText("₦1,500")).toBeTruthy();
    expect(within(screen.getByRole("list", { name: "Member benefits" })).getAllByRole("listitem")).toHaveLength(2);
    cleanup();
    render(<PlusSummary data={{
      plan, member: true,
      membership: { status: "active", member_since: "2026-11-01", paid_through: "2026-12-15", paid_through_text: "Tue 15 Dec 2026", days_left: 29, auto_renew: true, can_renew: false, periods: 2, savings_kobo: 245_000 },
    }} />);
    expect(screen.getByText(/until Tue 15 Dec 2026/)).toBeTruthy();
    expect(screen.getByText("₦2,450")).toBeTruthy();
    expect(screen.getByText(/renews from your wallet/)).toBeTruthy();
  });

  it("offers voucher steps for the points you have, shows vouchers and the referral code", () => {
    const onRedeem = vi.fn();
    render(<RewardsSummary data={rewards} onRedeem={onRedeem} />);
    expect(screen.getByText("1,240")).toBeTruthy();
    const steps = screen.getAllByRole("button", { name: /points →/ });
    expect(steps.map((b) => b.textContent)).toEqual(["500 points → ₦500", "1,000 points → ₦1,000"]);
    fireEvent.click(steps[1]!);
    expect(onRedeem).toHaveBeenCalledWith(1_000);
    expect(screen.getByLabelText("Your referral code").textContent).toBe("ADAO7K2P");
    expect(within(screen.getByRole("list", { name: "Your vouchers" })).getByText("GMP-3K7P9Q")).toBeTruthy();
    cleanup();
    render(<RewardsSummary data={{ ...rewards, points: 120, redeem: { ...rewards.redeem, redeemable_points: 0, points_to_next: 380 } }} />);
    expect(screen.getByText(/380 more points to your next ₦500 voucher/)).toBeTruthy();
    expect(screen.queryByRole("button", { name: /points →/ })).toBeNull();
  });

  it("shows who has paid their share and what is left", () => {
    render(<GroupBill group={group} />);
    const rows = within(screen.getByRole("list", { name: "Shares" })).getAllByRole("listitem");
    expect(rows.map((r) => r.textContent)).toEqual([
      expect.stringContaining("Not paid yet"),
      expect.stringMatching(/^You.*Paid$/),
      expect.stringContaining("Paid by Ada"),
    ]);
    expect(screen.getByRole("status").textContent).toContain("₦6,769.23 to go");
    cleanup();
    render(<GroupBill group={{ ...group, split_mode: "host" }} />);
    expect(screen.getByRole("heading", { name: "Ada is paying" })).toBeTruthy();
    expect(screen.queryByText("Not paid yet")).toBeNull();
  });

  it("lists everyone's items and lets you remove only your own", () => {
    const onRemove = vi.fn();
    render(<GroupItems group={{ ...group, status: "open" }} onRemove={onRemove} />);
    expect(screen.getByText("Chicken is unavailable")).toBeTruthy();
    const removes = screen.getAllByRole("button", { name: /Remove/ });
    expect(removes).toHaveLength(1);
    fireEvent.click(removes[0]!);
    expect(onRemove).toHaveBeenCalledWith("l1");
  });

  it("labels group order states and routes Gudy's buttons", () => {
    expect(groupStatusLabel({ ...group, status: "open" })).toBe("Collecting orders");
    expect(groupStatusLabel(group)).toBe("Waiting for everyone to pay");
    expect(groupStatusLabel({ ...group, split_mode: "host", order: { ...group.order!, status: "draft" } })).toBe("Waiting for the host to pay");
    expect(groupStatusLabel({ ...group, status: "expired" })).toBe("Expired");
    expect([routeForScreen("plus"), routeForScreen("rewards"), routeForScreen("group")]).toEqual(["/plus", "/rewards", "/group"]);
  });
});

describe("Connect WhatsApp", () => {
  afterEach(cleanup);
  const status = { enabled: true, linked: false, number: null, linked_at: null, business_number: "+234 800 000 0000", chat_link: null };

  it("offers to connect, then shows the code to send, then the connected number", async () => {
    const { WhatsAppConnectView } = await import("./whatsapp-connect");
    const onConnect = vi.fn();
    render(<WhatsAppConnectView status={status} onConnect={onConnect} onDisconnect={vi.fn()} />);
    fireEvent.click(screen.getByRole("button", { name: "Connect WhatsApp" }));
    expect(onConnect).toHaveBeenCalled();
    cleanup();
    render(<WhatsAppConnectView status={status} onConnect={vi.fn()} onDisconnect={vi.fn()}
      code={{ code: "123456", expires_at: "2026-11-16T12:10:00Z", business_number: "+234 800 000 0000", wa_link: "https://wa.me/2348000000000?text=LINK%20123456" }} />);
    expect(screen.getByLabelText("Your WhatsApp code").textContent).toBe("123456");
    expect(screen.getByRole("link").getAttribute("href")).toBe("https://wa.me/2348000000000?text=LINK%20123456");
    cleanup();
    const onDisconnect = vi.fn();
    render(<WhatsAppConnectView status={{ ...status, linked: true, number: "+234 801 ••• 1111", chat_link: "https://wa.me/2348000000000" }}
      onConnect={vi.fn()} onDisconnect={onDisconnect} />);
    expect(screen.getByText("+234 801 ••• 1111")).toBeTruthy();
    fireEvent.click(screen.getByRole("button", { name: "Disconnect" }));
    expect(onDisconnect).toHaveBeenCalled();
    cleanup();
    render(<WhatsAppConnectView status={{ ...status, enabled: false }} onConnect={vi.fn()} onDisconnect={vi.fn()} />);
    expect(screen.getByText(/coming soon/)).toBeTruthy();
    expect(screen.queryByRole("button")).toBeNull();
  });
});
