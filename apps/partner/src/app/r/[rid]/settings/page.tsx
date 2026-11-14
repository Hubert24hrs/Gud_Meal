"use client";

import { Button, Card, ErrorState, Field, Input, Skeleton, Toggle } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { use, useEffect, useState } from "react";
import { useApi } from "@/lib/api";

const DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

export default function SettingsPage({ params }: { params: Promise<{ rid: string }> }) {
  const { rid } = use(params);
  const api = useApi();
  const qc = useQueryClient();
  const menu = useQuery({ queryKey: ["menu", rid], queryFn: () => api.partner.menu(rid) });
  const r = menu.data?.restaurant;
  const [hours, setHours] = useState<{ open: string; close: string; closed: boolean }[]>([]);
  const [prep, setPrep] = useState(20);
  const [pickup, setPickup] = useState(true);
  const [delivery, setDelivery] = useState(true);
  const [description, setDescription] = useState("");

  useEffect(() => {
    if (!r) return;
    setHours(DAYS.map((_, i) => {
      const range = r.opening_hours.weekly[String(i)]?.[0];
      return range ? { open: range.open, close: range.close, closed: false } : { open: "09:00", close: "21:00", closed: true };
    }));
    setPrep(r.avg_prep_minutes);
    setPickup(r.supports_pickup);
    setDelivery(r.supports_delivery);
    setDescription(r.description);
  }, [r]);

  const save = useMutation({
    mutationFn: () => api.partner.settings(rid, {
      avg_prep_minutes: prep, supports_pickup: pickup, supports_delivery: delivery, description,
      opening_hours: {
        timezone: "Africa/Lagos", closed_dates: r?.opening_hours.closed_dates ?? [],
        weekly: Object.fromEntries(hours.flatMap((h, i) => (h.closed ? [] : [[String(i), [{ open: h.open, close: h.close }]]]))),
      },
    }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["menu", rid] }),
  });

  if (menu.isLoading || !r) return <Skeleton className="h-96" />;
  return (
    <div className="max-w-2xl space-y-6">
      <h2 className="font-display text-2xl">Settings</h2>
      <Card className="space-y-4 p-5">
        <h3 className="font-semibold">Opening hours (Lagos time)</h3>
        {hours.map((h, i) => (
          <div key={DAYS[i]} className="flex flex-wrap items-center gap-3 text-sm">
            <span className="w-28 font-medium">{DAYS[i]}</span>
            <Toggle checked={!h.closed} label={h.closed ? "Closed" : "Open"} onChange={(v) => setHours((all) => all.map((x, j) => (j === i ? { ...x, closed: !v } : x)))} />
            {!h.closed && (
              <>
                <Input type="time" value={h.open} aria-label={`${DAYS[i]} opening time`} className="h-9 w-32"
                  onChange={(e) => setHours((all) => all.map((x, j) => (j === i ? { ...x, open: e.target.value } : x)))} />
                <span>to</span>
                <Input type="time" value={h.close} aria-label={`${DAYS[i]} closing time`} className="h-9 w-32"
                  onChange={(e) => setHours((all) => all.map((x, j) => (j === i ? { ...x, close: e.target.value } : x)))} />
              </>
            )}
          </div>
        ))}
        <p className="text-xs text-muted">Closing earlier than opening means you trade past midnight (e.g. 16:00 – 02:00).</p>
      </Card>
      <Card className="space-y-4 p-5">
        <Field label="Average preparation time (minutes)" htmlFor="prep">
          <Input id="prep" type="number" min={1} max={180} value={prep} onChange={(e) => setPrep(Number(e.target.value))} className="w-32" />
        </Field>
        <Field label="Description" htmlFor="desc"><Input id="desc" value={description} onChange={(e) => setDescription(e.target.value)} maxLength={500} /></Field>
        <div className="flex flex-wrap gap-6">
          <Toggle checked={delivery} onChange={setDelivery} label="Delivery" />
          <Toggle checked={pickup} onChange={setPickup} label="Pickup" />
        </div>
      </Card>
      {save.error && <ErrorState message={(save.error as Error).message} />}
      <div className="flex items-center gap-3">
        <Button onClick={() => save.mutate()} loading={save.isPending}>Save changes</Button>
        {save.isSuccess && <span className="text-sm text-secondary">Saved</span>}
      </div>
    </div>
  );
}
