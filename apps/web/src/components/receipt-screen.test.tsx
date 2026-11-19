import { ApiError, type Receipt } from "@gudmeal/api-client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";

/** The receipt printer shown after a payment (ADR-0019). */
const getReceipt = vi.fn();
const printReceipt = vi.fn();
vi.mock("@/lib/api", () => ({ useApi: () => ({ orders: { receipt: getReceipt, printReceipt } }) }));
vi.mock("next/link", () => ({
  default: ({ href, children, className }: { href: string; children: React.ReactNode; className?: string }) => <a href={href} className={className}>{children}</a>,
}));

const { ReceiptScreen } = await import("./receipt-screen");
const { ReceiptPrinter } = await import("./ui/receipt-printer");

const receipt = (over: Partial<Receipt> = {}): Receipt => ({
  id: "o1", number: "YC-7K2M9P", order_id: "o1", order_code: "7K2M9P", customer_id: "u1", customer_name: "Ada Obi", service: "food",
  service_name: "Food", seller: "Jollof Junction", seller_address: "12 Admiralty Way, Lekki Phase 1", summary: [],
  lines: [
    { name: "Party Jollof Rice", quantity: 2, amount_kobo: 1_100_000, details: ["Protein: Chicken"] },
    { name: "Chapman", quantity: 2, amount_kobo: 300_000, details: [] },
  ],
  charges: [
    { label: "Subtotal", amount_kobo: 1_400_000 },
    { label: "Delivery fee", amount_kobo: 90_000 },
    { label: "Service fee", amount_kobo: 70_000 },
    { label: "VAT", amount_kobo: 12_000 },
    { label: "Discount", amount_kobo: -50_000 },
  ],
  total_kobo: 1_522_000, savings_kobo: 0, refunded_kobo: 0, paid_with: "Card, bank transfer or USSD", payment_reference: "YC-ABC123",
  paid_at: "2026-11-17T08:30:00Z", ordered_at: "2026-11-17T08:29:00Z", issued_at: "2026-11-17T08:30:05Z", printed_at: null,
  print_count: 0, saved: false, ...over,
});

function show(ui: React.ReactNode) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(<QueryClientProvider client={qc}>{ui}</QueryClientProvider>);
}

beforeAll(() => {
  // jsdom has no modal dialogs
  HTMLDialogElement.prototype.showModal ??= function (this: HTMLDialogElement) { this.setAttribute("open", ""); };
  HTMLDialogElement.prototype.close ??= function (this: HTMLDialogElement) { this.removeAttribute("open"); };
});
afterEach(() => {
  cleanup();
  getReceipt.mockReset();
  printReceipt.mockReset();
});

describe("receipt printer", () => {
  it("is a Yummy Chops printer that says what to do, in plain sight", () => {
    render(<ReceiptPrinter receipt={receipt()} />);
    expect(screen.getByText("Yummy Chops")).toBeTruthy(); // the maker's mark; nothing is printed yet
    expect(screen.queryByText("Total paid")).toBeNull();
    const hint = screen.getByText("Press the red PRINT button to print your receipt");
    expect(hint.className).toContain("font-bold");
    expect(screen.getByRole("button", { name: "Print receipt" }).textContent).toBe("PRINT");
  });

  it("prints what was paid for when PRINT is pressed, and the paper can be torn off", async () => {
    const onPrint = vi.fn();
    render(<ReceiptPrinter receipt={receipt()} onPrint={onPrint} />);
    fireEvent.click(screen.getByRole("button", { name: "Print receipt" }));
    await waitFor(() => expect(onPrint).toHaveBeenCalledTimes(1));

    const paper = screen.getByRole("button", { name: /Pull it, or press Enter, to tear it off/ });
    for (const text of [
      "Jollof Junction", "12 Admiralty Way, Lekki Phase 1", "Receipt YC-7K2M9P", "Order #7K2M9P", "Ada Obi", "2 x Party Jollof Rice",
      "₦11,000", "Protein: Chicken", "2 x Chapman", "Subtotal", "₦14,000", "Delivery fee", "Service fee", "VAT", "-₦500",
      "Total paid", "₦15,220", "Card, bank transfer or USSD", "Ref YC-ABC123", "THANK YOU",
    ]) {
      expect(within(paper).getByText(text), text).toBeTruthy();
    }
    expect(screen.getByText("Printing your receipt… press PRINT to stop")).toBeTruthy();

    // PRINT again stops the feed; once more prints a second copy onto the same strip.
    fireEvent.click(screen.getByRole("button", { name: "Print receipt" }));
    await waitFor(() => expect(screen.getByText("Pull the receipt to tear it off, or press PRINT for another copy")).toBeTruthy());
    fireEvent.click(screen.getByRole("button", { name: "Print receipt" }));
    await waitFor(() => expect(onPrint).toHaveBeenCalledTimes(2));
    expect(within(paper).getAllByText("Total paid")).toHaveLength(2);

    fireEvent.keyDown(paper, { key: "Enter" });
    expect(screen.queryByRole("button", { name: /Pull it, or press Enter/ })).toBeNull();
    expect(screen.getByText("Press the red PRINT button to print your receipt")).toBeTruthy();
  });

  it("prints a package receipt, refunds and Plus savings", async () => {
    render(<ReceiptPrinter receipt={receipt({
      seller: "Yummy Chops", seller_address: "Package Delivery", service_name: "Package Delivery", lines: [],
      summary: ["From Lekki Phase 1 to Victoria Island", "Small package: documents"], charges: [{ label: "Delivery fee", amount_kobo: 150_000 }],
      total_kobo: 150_000, paid_with: "Yummy Chops wallet", payment_reference: null, refunded_kobo: 150_000, savings_kobo: 20_000,
    })} />);
    fireEvent.click(screen.getByRole("button", { name: "Print receipt" }));
    const paper = await screen.findByRole("button", { name: /Pull it/ });
    expect(within(paper).getByText("From Lekki Phase 1 to Victoria Island")).toBeTruthy();
    expect(within(paper).getByText("Yummy Chops wallet")).toBeTruthy();
    expect(within(paper).getByText("Refunded")).toBeTruthy();
    expect(within(paper).getByText("Saved with Yummy Chops Plus")).toBeTruthy();
    expect(within(paper).queryByText(/^Ref /)).toBeNull();
  });
});

describe("receipt screen after paying", () => {
  it("keeps the receipt under My receipts when PRINT is pressed", async () => {
    getReceipt.mockResolvedValue(receipt());
    printReceipt.mockResolvedValue(receipt({ saved: true, print_count: 1, printed_at: "2026-11-17T08:31:00Z" }));
    show(<ReceiptScreen orderId="o1" />);
    const print = await screen.findByRole("button", { name: "Print receipt" });
    expect(getReceipt).toHaveBeenCalledWith("o1");
    expect(screen.queryByRole("status")).toBeNull(); // not kept until it is printed
    expect(screen.getByRole("link", { name: "Track my order" }).getAttribute("href")).toBe("/orders/o1");
    expect(screen.getByRole("link", { name: "My receipts" }).getAttribute("href")).toBe("/receipts");

    fireEvent.click(print);
    await waitFor(() => expect(printReceipt).toHaveBeenCalledWith("o1"));
    expect((await screen.findByRole("status")).textContent).toBe("Saved to My receipts");

    // A long receipt can be read in full.
    fireEvent.click(screen.getByRole("button", { name: "Read receipt" }));
    const dialog = document.querySelector("dialog")!;
    expect(dialog.hasAttribute("open")).toBe(true);
    expect(within(dialog).getByText("Total paid")).toBeTruthy();
  });

  it("says so when the receipt could not be saved, so the customer can press PRINT again", async () => {
    getReceipt.mockResolvedValue(receipt());
    printReceipt.mockRejectedValue(new Error("offline"));
    show(<ReceiptScreen orderId="o1" />);
    fireEvent.click(await screen.findByRole("button", { name: "Print receipt" }));
    expect(await screen.findByText("Could not save the receipt. Check your connection, then press PRINT again")).toBeTruthy();
    expect(screen.queryByRole("status")).toBeNull();
  });

  it("has no receipt for an order that is not paid for", async () => {
    getReceipt.mockRejectedValue(new ApiError(409, "order_not_paid", "This order has not been paid for yet, so there is no receipt"));
    show(<ReceiptScreen orderId="o1" />);
    expect(await screen.findByRole("heading", { name: "No receipt yet" })).toBeTruthy();
    expect(screen.queryByRole("button", { name: "Print receipt" })).toBeNull();
    expect(screen.getByRole("link", { name: "Back to the order" }).getAttribute("href")).toBe("/orders/o1");
  });
});
