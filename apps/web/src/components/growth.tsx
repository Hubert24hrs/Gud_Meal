"use client";

import { formatDateTime, formatNaira, formatTime, ORDER_STATUS, type GroupOrder, type PlusOverview, type RewardsOverview } from "@gudmeal/api-client";
import { Badge, Button, Card, cn } from "@gudmeal/ui";
import { BadgeCheck, Check, Copy, Crown, Gift, Share2, Trash2, Users } from "lucide-react";
import { useState, type ReactNode } from "react";

/** Copy or share text (Web Share where the browser has it, else the clipboard). */
export function ShareButton({ text, url, label = "Share" }: { text: string; url?: string; label?: string }) {
  const [done, setDone] = useState(false);
  async function share() {
    const full = url ? `${text} ${url}` : text;
    try {
      if (typeof navigator.share === "function") {
        await navigator.share({ text, url });
        return;
      }
      await navigator.clipboard.writeText(full);
      setDone(true);
      setTimeout(() => setDone(false), 2000);
    } catch {
      /* the person closed the share sheet */
    }
  }
  return (
    <Button type="button" variant="outline" size="sm" onClick={share}>
      {done ? <Check className="size-4" aria-hidden="true" /> : <Share2 className="size-4" aria-hidden="true" />}
      {done ? "Copied" : label}
    </Button>
  );
}

// ------------------------------------------------------------------------------------------- Plus
export function PlusSummary({ data, children }: { data: PlusOverview; children?: ReactNode }) {
  const { plan, member, membership } = data;
  return (
    <div className="space-y-5">
      <div className="rounded-3xl bg-gradient-to-br from-[#3A1A0C] via-[#7A2E12] to-primary p-6 text-white shadow-card">
        <p className="flex items-center gap-2 text-sm font-semibold text-white/90">
          <Crown className="size-4" aria-hidden="true" /> GudMeals Plus
        </p>
        <p className="mt-1 text-4xl font-black tracking-tight">
          {formatNaira(plan.price_kobo)}<span className="text-lg font-bold"> / {plan.period_days} days</span>
        </p>
        <p className="text-xs text-white/80">VAT included · cancel any time</p>
        <ul className="mt-4 space-y-1.5" aria-label="Member benefits">
          {plan.benefits.map((b) => (
            <li key={b} className="flex items-start gap-2 text-sm"><BadgeCheck className="mt-0.5 size-4 shrink-0" aria-hidden="true" />{b}</li>
          ))}
        </ul>
      </div>
      {member && membership && (
        <Card className="space-y-2 p-5" aria-label="Your membership">
          <p className="flex items-center gap-2 text-lg font-extrabold"><Badge tone="success">Member</Badge> until {membership.paid_through_text}</p>
          <p className="text-sm text-muted">{membership.days_left} days left · {membership.auto_renew ? "renews from your wallet" : "auto-renew is off"}</p>
          <p className="text-sm">You&apos;ve saved <strong>{formatNaira(membership.savings_kobo)}</strong> with Plus so far.</p>
        </Card>
      )}
      {!member && membership?.status === "expired" && (
        <p className="rounded-md bg-accent-soft p-3 text-sm">Your membership ended. Join again to get your benefits back.</p>
      )}
      {children}
    </div>
  );
}

// ------------------------------------------------------------------------------------------- rewards
export function RewardsSummary({ data, onRedeem, redeeming = false }: {
  data: RewardsOverview; onRedeem?: (points: number) => void; redeeming?: boolean;
}) {
  const { redeem, referral } = data;
  const steps = Math.min(10, Math.floor(redeem.redeemable_points / redeem.step_points));
  const progress = Math.max(0, Math.min(100, ((redeem.step_points - redeem.points_to_next) / redeem.step_points) * 100));
  return (
    <div className="space-y-5">
      <div className="rounded-3xl bg-gradient-to-br from-[#6B2410] to-[#3A0D05] p-6 text-white shadow-card">
        <p className="flex items-center gap-2 text-sm font-semibold text-white/90"><Gift className="size-4" aria-hidden="true" /> Gud points</p>
        <p className="mt-1 text-5xl font-black tracking-tight" aria-live="polite">{data.points.toLocaleString()}</p>
        <p className="text-sm text-white/90">Worth {formatNaira(data.points_value_kobo)} · {data.earn.points_per_100_naira} point per ₦100 on completed orders
          {data.earn.plus_multiplier > 1 && ` (${data.earn.plus_multiplier}× with GudMeals Plus${data.earn.member ? ", that's you" : ""})`}</p>
        {steps === 0 && redeem.enabled && (
          <div className="mt-4">
            <div className="h-2 overflow-hidden rounded-full bg-white/25"><div className="h-full rounded-full bg-white" style={{ width: `${progress}%` }} /></div>
            <p className="mt-1 text-xs">{redeem.points_to_next.toLocaleString()} more points to your next {formatNaira(redeem.step_value_kobo)} voucher</p>
          </div>
        )}
      </div>

      {steps > 0 && onRedeem && (
        <Card className="space-y-3 p-5">
          <h2 className="text-lg font-extrabold">Turn points into a voucher</h2>
          <div className="flex flex-wrap gap-2">
            {Array.from({ length: steps }, (_, i) => (i + 1) * redeem.step_points).map((p) => (
              <Button key={p} type="button" variant={p === redeem.step_points ? "primary" : "outline"} disabled={redeeming} onClick={() => onRedeem(p)}>
                {p.toLocaleString()} points → {formatNaira((p / redeem.step_points) * redeem.step_value_kobo)}
              </Button>
            ))}
          </div>
          <p className="text-xs text-muted">Vouchers work on restaurant and shop orders from {formatNaira(redeem.min_subtotal_kobo)} and last {redeem.valid_days} days.</p>
        </Card>
      )}

      {data.vouchers.length > 0 && (
        <Card className="space-y-3 p-5">
          <h2 className="text-lg font-extrabold">Your vouchers</h2>
          <ul className="divide-y divide-border" aria-label="Your vouchers">
            {data.vouchers.map((v) => (
              <li key={v.code} className="flex items-center gap-3 py-2.5">
                <span className="min-w-0 flex-1">
                  <span className="block font-bold">{formatNaira(v.value_kobo)} off</span>
                  <span className="block text-xs text-muted">{v.description} · orders from {formatNaira(v.min_subtotal_kobo)}{v.ends_at ? ` · until ${formatDateTime(v.ends_at)}` : ""}</span>
                </span>
                <code className="rounded bg-surface-muted px-2 py-1 font-mono text-sm">{v.code}</code>
              </li>
            ))}
          </ul>
          <p className="text-xs text-muted">Pick one at checkout. Each voucher is yours alone and works once.</p>
        </Card>
      )}

      {referral.enabled && (
        <Card className="space-y-3 p-5">
          <h2 className="flex items-center gap-2 text-lg font-extrabold"><Users className="size-5 text-primary" aria-hidden="true" /> Invite friends</h2>
          <p className="text-sm">Friends get <strong>{formatNaira(referral.friend_gets_kobo)}</strong> off their first order; you get <strong>{formatNaira(referral.you_get_kobo)}</strong> when it&apos;s delivered.</p>
          <div className="flex flex-wrap items-center gap-3">
            <code className="rounded-lg border-2 border-dashed border-primary px-4 py-2 font-mono text-xl font-black tracking-widest" aria-label="Your referral code">{referral.code}</code>
            <ShareButton text={referral.share_text} label="Share my code" />
          </div>
          {referral.friends_rewarded > 0 && <p className="text-sm text-muted">{referral.friends_rewarded} friend{referral.friends_rewarded === 1 ? "" : "s"} rewarded so far.</p>}
        </Card>
      )}

      {data.history.length > 0 && (
        <Card className="space-y-2 p-5">
          <h2 className="text-lg font-extrabold">History</h2>
          <ul className="divide-y divide-border text-sm" aria-label="Points history">
            {data.history.map((e) => (
              <li key={e.id} className="flex items-center justify-between gap-3 py-2">
                <span>{e.kind === "earned" ? "Order completed" : e.kind === "redeemed" ? `Voucher ${e.voucher_code ?? ""}` : "Refund"}{e.note ? <span className="text-muted"> · {e.note}</span> : null}
                  <span className="block text-xs text-muted">{formatDateTime(e.at)}</span></span>
                <strong className={cn(e.points > 0 ? "text-secondary" : "text-text")}>{e.points > 0 ? "+" : ""}{e.points.toLocaleString()}</strong>
              </li>
            ))}
          </ul>
        </Card>
      )}
    </div>
  );
}

// ------------------------------------------------------------------------------------------- group orders
export function groupStatusLabel(g: Pick<GroupOrder, "status" | "order" | "split_mode">): string {
  if (g.status === "open") return "Collecting orders";
  if (g.status === "locked") return "Cart locked by the host";
  if (g.status === "cancelled") return "Cancelled";
  if (g.status === "expired") return "Expired";
  if (g.order?.status === "pending_payment") return "Waiting for everyone to pay";
  if (g.order?.status === "draft") return g.split_mode === "host" ? "Waiting for the host to pay" : "Order placed";
  return g.order ? ORDER_STATUS[g.order.status]?.label ?? g.order.status : "Order placed";
}

export function GroupItems({ group, onRemove, busy = false }: { group: GroupOrder; onRemove?: (lineId: string) => void; busy?: boolean }) {
  const byMember = group.members.map((m) => ({ m, lines: group.lines.filter((l) => l.member_uid === m.uid) }));
  return (
    <ul className="space-y-4" aria-label="Everyone's items">
      {byMember.map(({ m, lines }) => (
        <li key={m.uid}>
          <p className="flex items-center gap-2 text-sm font-bold">
            {m.me ? "You" : m.name}{m.is_host && <Badge tone="progress">Host</Badge>}{m.ready && <Badge tone="success">Ready</Badge>}
            <span className="ml-auto font-semibold text-muted">{formatNaira(m.items_kobo)}</span>
          </p>
          {lines.length === 0 ? <p className="text-sm text-muted">Nothing yet</p> : (
            <ul className="mt-1 space-y-1">
              {lines.map((l) => (
                <li key={l.id} className="flex items-start gap-2 text-sm">
                  <span className="min-w-0 flex-1">{l.quantity} × {l.name}
                    {l.options.length > 0 && <span className="block text-xs text-muted">{l.options.join(" · ")}</span>}
                    {l.problem && <span className="block text-xs font-semibold text-danger">{l.problem}</span>}
                  </span>
                  <span>{formatNaira(l.line_total_kobo)}</span>
                  {m.me && onRemove && (
                    <button type="button" disabled={busy} onClick={() => onRemove(l.id)} className="text-muted hover:text-danger" aria-label={`Remove ${l.name}`}>
                      <Trash2 className="size-4" aria-hidden="true" />
                    </button>
                  )}
                </li>
              ))}
            </ul>
          )}
        </li>
      ))}
    </ul>
  );
}

/** The bill after the host placed the order: everyone's share and who has paid. */
export function GroupBill({ group, children }: { group: GroupOrder; children?: ReactNode }) {
  const each = group.split_mode === "each";
  return (
    <Card className="space-y-3 p-5">
      <div className="flex items-baseline justify-between gap-3">
        <h2 className="text-lg font-extrabold">{each ? "Who pays what" : `${group.host_name} is paying`}</h2>
        <strong className="text-lg">{formatNaira(group.total_kobo)}</strong>
      </div>
      <p className="text-xs text-muted">Each person pays for their own items. Delivery, fees, VAT and any discount are shared in proportion to what each person ordered.</p>
      <ul className="divide-y divide-border" aria-label="Shares">
        {group.shares.map((s) => (
          <li key={s.uid} className="flex items-center justify-between gap-3 py-2 text-sm">
            <span className={cn(s.me && "font-bold")}>{s.me ? "You" : s.name}<span className="block text-xs text-muted">items {formatNaira(s.items_kobo)}</span></span>
            <span className="text-right">
              <strong>{formatNaira(s.amount_kobo)}</strong>
              {each && (
                <span className={cn("block text-xs", s.status === "paid" ? "text-secondary" : "text-muted")}>
                  {s.status === "paid" ? (s.paid_by_host ? `Paid by ${group.host_name}` : "Paid") : "Not paid yet"}
                </span>
              )}
            </span>
          </li>
        ))}
      </ul>
      {each && group.remaining_kobo > 0 && (
        <p className="rounded-md bg-accent-soft p-3 text-sm" role="status">
          {formatNaira(group.paid_kobo)} paid, {formatNaira(group.remaining_kobo)} to go
          {group.pay_by && ` · everyone needs to pay by ${formatTime(group.pay_by)} or the order is cancelled and refunded`}.
        </p>
      )}
      {children}
    </Card>
  );
}

export function CodeChip({ code }: { code: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <button type="button" onClick={() => navigator.clipboard?.writeText(code).then(() => { setCopied(true); setTimeout(() => setCopied(false), 1500); })}
      className="inline-flex items-center gap-2 rounded-lg border-2 border-dashed border-primary px-3 py-1.5 font-mono text-lg font-black tracking-widest"
      aria-label={`Group code ${code}, copy`}>
      {code}{copied ? <Check className="size-4" aria-hidden="true" /> : <Copy className="size-4" aria-hidden="true" />}
    </button>
  );
}
