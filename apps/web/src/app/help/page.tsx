import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = { title: "Help centre", description: "Answers about fees, payments, refunds, delivery codes and your data." };

const FAQ = [
  ["How are fees calculated?", "Delivery fees depend on distance and are shown before you pay. A 5% service fee (min ₦100, max ₦1,500) applies, plus a small-order fee under ₦3,000. VAT (7.5%) applies to platform fees. The total you approve is exactly what you pay."],
  ["Is my payment safe?", "Payments are processed on a secure page by our payment partners. Yummy Chops never sees your card details and will never ask for your PIN or OTP."],
  ["What if the restaurant can't fulfil my order?", "If a restaurant rejects or doesn't confirm your paid order in time, you're refunded in full automatically."],
  ["Something was missing or wrong", "Open the order and tap “Report an issue” within 48 hours. Our team reviews it and refunds approved amounts to your original payment method."],
  ["What is the delivery code?", "A 4-digit code shown on your order. Give it to the rider only when you have your food — it confirms the delivery."],
  ["Can I cancel?", "Yes, until the restaurant accepts your order. After that the kitchen has started cooking — contact support."],
];

export default function HelpPage() {
  return (
    <div className="container-page max-w-3xl space-y-8 py-10">
      <h1 className="font-display text-4xl">Help centre</h1>
      <div className="divide-y divide-border rounded-lg border border-border bg-surface">
        {FAQ.map(([q, a]) => (
          <details key={q} className="group p-5">
            <summary className="cursor-pointer list-none font-semibold marker:hidden">{q}</summary>
            <p className="mt-2 text-sm text-muted">{a}</p>
          </details>
        ))}
      </div>
      <section id="privacy" className="space-y-2 text-sm text-muted">
        <h2 className="font-display text-2xl text-text">Privacy</h2>
        <p>We process your data under the Nigeria Data Protection Act 2023 to deliver orders, prevent fraud and — with your consent — personalise recommendations. You can download your data from your account page or ask us to delete it.</p>
      </section>
      <section id="terms" className="space-y-2 text-sm text-muted">
        <h2 className="font-display text-2xl text-text">Terms</h2>
        <p>Orders are prepared by independent partner restaurants. Prices include VAT where applicable. Full terms will be published before launch.</p>
      </section>
      <p className="text-sm">Still stuck? <Link href="/assistant" className="font-semibold text-primary">Ask Yummy Chops</Link>.</p>
    </div>
  );
}
