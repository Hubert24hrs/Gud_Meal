"use client";

import { ApiError, type HubItem } from "@gudmeal/api-client";
import { Badge, Button, Card, DataTable, ErrorState, Field, Input, Select, Skeleton } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { useApi } from "@/lib/api";

const CODE = /^GMW[2-9A-HJ-NP-Z]{8}$/;
const clean = (raw: string) => raw.toUpperCase().replace(/[\s-]/g, "");
const message = (e: unknown) => (e instanceof ApiError || e instanceof Error ? e.message : "Something went wrong");

/** Hub console: receive packages, send loads with a carrier, take arrivals and hand over collections. */
export default function HubsPage() {
  const api = useApi();
  const qc = useQueryClient();
  const hubs = useQuery({ queryKey: ["hubs"], queryFn: () => api.admin.hubs() });
  const [hubId, setHubId] = useState("");
  useEffect(() => {
    if (!hubId && hubs.data?.length) setHubId(hubs.data[0]!.id);
  }, [hubs.data, hubId]);
  const board = useQuery({
    queryKey: ["hub-board", hubId], queryFn: () => api.admin.hubBoard(hubId), enabled: Boolean(hubId), refetchInterval: 20_000,
  });
  const [scan, setScan] = useState("");
  const [notice, setNotice] = useState<string | null>(null);
  const [selected, setSelected] = useState<string[]>([]);
  const [trip, setTrip] = useState("");
  const refresh = () => qc.invalidateQueries({ queryKey: ["hub-board", hubId] });

  const act = useMutation({
    mutationFn: async ({ kind, code, pin }: { kind: "receive" | "arrive" | "collect"; code: string; pin?: string }) => {
      if (!CODE.test(code)) throw new Error("Tracking numbers look like GMW followed by 8 letters and numbers");
      if (kind === "receive") return api.admin.receiveWaybill(hubId, code);
      if (kind === "arrive") return api.admin.arriveWaybill(hubId, code);
      if (!pin || !/^\d{4}$/.test(pin)) throw new Error("Enter the recipient's 4-digit collection code");
      return api.admin.collectWaybill(hubId, code, pin);
    },
    onSuccess: (item) => { setNotice(`${item.tracking_code}: ${item.label}`); setScan(""); refresh(); },
  });
  const depart = useMutation({
    mutationFn: () => api.admin.departWaybills(hubId, selected, trip.trim()),
    onSuccess: (res) => {
      setNotice(`${res.departed.length} package(s) departed${res.skipped.length ? `; skipped ${res.skipped.map((s) => `${s.tracking_code} (${s.reason})`).join(", ")}` : ""}`);
      setSelected([]);
      setTrip("");
      refresh();
    },
  });

  const b = board.data;
  const hub = hubs.data?.find((h) => h.id === hubId);
  const toggle = (code: string) => setSelected((s) => (s.includes(code) ? s.filter((c) => c !== code) : [...s, code]));
  const collect = (code: string) => act.mutate({ kind: "collect", code, pin: window.prompt(`Collection code for ${code}`) ?? "" });
  const base = [
    { key: "t", header: "Tracking", render: (x: HubItem) => <span className="font-mono text-xs font-bold">{x.tracking_code}</span> },
    { key: "r", header: "Route", render: (x: HubItem) => `${x.origin} → ${x.destination}` },
    { key: "p", header: "Package", render: (x: HubItem) => `${x.size}, ${x.weight_kg} kg${x.description ? `, ${x.description}` : ""}` },
  ];

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl">Hubs</h1>
          <p className="text-sm text-muted">Interstate waybills at your hub. Scan or type the tracking number on the package.</p>
        </div>
        {hubs.isLoading ? <Skeleton className="h-11 w-64" /> : (
          <Field label="Hub" htmlFor="hub">
            <Select id="hub" value={hubId} onChange={(e) => { setHubId(e.target.value); setSelected([]); setNotice(null); }}>
              {hubs.data?.map((h) => <option key={h.id} value={h.id}>{h.name} ({h.city_name})</option>)}
            </Select>
          </Field>
        )}
      </div>
      {hubs.error && <ErrorState message={message(hubs.error)} />}
      {hub?.is_sample && <p className="rounded-md bg-accent-soft p-3 text-sm">This is a sample hub (placeholder address and phone) until real hubs are set up.</p>}

      <Card className="space-y-3 p-5">
        <h2 className="font-semibold">Scan a package</h2>
        <form className="flex flex-wrap items-end gap-2" onSubmit={(e) => { e.preventDefault(); act.mutate({ kind: "receive", code: clean(scan) }); }}>
          <div className="min-w-56 flex-1">
            <Field label="Tracking number" htmlFor="scan"><Input id="scan" value={scan} onChange={(e) => setScan(e.target.value)} placeholder="GMW…" /></Field>
          </div>
          <Button type="submit" loading={act.isPending}>Receive here</Button>
          <Button type="button" variant="outline" onClick={() => act.mutate({ kind: "arrive", code: clean(scan) })}>Arrived here</Button>
          <Button type="button" variant="outline" onClick={() => collect(clean(scan))}>Hand over</Button>
        </form>
        {(act.error || depart.error) && <ErrorState message={message(act.error ?? depart.error)} />}
        {notice && <p className="text-sm font-semibold text-secondary" role="status">{notice}</p>}
      </Card>

      {board.isLoading ? <Skeleton className="h-64" /> : board.error ? <ErrorState message={message(board.error)} /> : b && (
        <>
          <Card className="space-y-3 p-5">
            <h2 className="font-semibold">Expected here ({b.expected.length})</h2>
            <DataTable rows={b.expected} rowKey={(x) => x.tracking_code} empty="Nothing expected" columns={[
              ...base,
              { key: "s", header: "Sender", render: (x) => <span>{x.sender.name}<span className="block text-xs text-muted">{x.sender.phone}</span></span> },
              { key: "h", header: "Coming by", render: (x) => (x.first_mile === "pickup" ? "Rider" : "Drop-off") },
              { key: "a", header: "", render: (x) => <Button size="sm" onClick={() => act.mutate({ kind: "receive", code: x.tracking_code })}>Receive</Button> },
            ]} />
          </Card>

          <Card className="space-y-3 p-5">
            <h2 className="font-semibold">At this hub, waiting to leave ({b.at_hub.length})</h2>
            <DataTable rows={b.at_hub} rowKey={(x) => x.tracking_code} empty="No packages waiting" columns={[
              { key: "x", header: "", render: (x) => (
                <input type="checkbox" aria-label={`Select ${x.tracking_code}`} checked={selected.includes(x.tracking_code)} onChange={() => toggle(x.tracking_code)} />
              ) },
              ...base,
              { key: "c", header: "Carrier", render: (x) => x.carrier },
              { key: "e", header: "Expected", render: (x) => x.eta_text },
            ]} />
            <form className="flex flex-wrap items-end gap-2" onSubmit={(e) => { e.preventDefault(); depart.mutate(); }}>
              <Field label="Carrier trip or manifest number" htmlFor="trip"><Input id="trip" value={trip} onChange={(e) => setTrip(e.target.value)} /></Field>
              <Button type="submit" disabled={!selected.length || trip.trim().length < 2} loading={depart.isPending}>
                Mark {selected.length || ""} departed
              </Button>
            </form>
          </Card>

          <Card className="space-y-3 p-5">
            <h2 className="font-semibold">On the way here ({b.incoming.length})</h2>
            <DataTable rows={b.incoming} rowKey={(x) => x.tracking_code} empty="Nothing on the way" columns={[
              ...base,
              { key: "trip", header: "Trip", render: (x) => x.trip_reference ?? "—" },
              { key: "m", header: "Then", render: (x) => (x.last_mile === "door" ? "Door delivery" : "Collection") },
              { key: "a", header: "", render: (x) => <Button size="sm" onClick={() => act.mutate({ kind: "arrive", code: x.tracking_code })}>Arrived</Button> },
            ]} />
          </Card>

          <Card className="space-y-3 p-5">
            <h2 className="font-semibold">Waiting for collection ({b.for_collection.length})</h2>
            <DataTable rows={b.for_collection} rowKey={(x) => x.tracking_code} empty="No collections waiting" columns={[
              ...base,
              { key: "r2", header: "Recipient", render: (x) => <span>{x.recipient.name}<span className="block text-xs text-muted">{x.recipient.phone}</span></span> },
              { key: "a", header: "", render: (x) => <Button size="sm" onClick={() => collect(x.tracking_code)}>Hand over</Button> },
            ]} />
          </Card>

          <Card className="space-y-3 p-5">
            <h2 className="font-semibold">Out for door delivery ({b.out_for_delivery.length})</h2>
            <DataTable rows={b.out_for_delivery} rowKey={(x) => x.tracking_code} empty="None" columns={[
              ...base,
              { key: "r2", header: "Recipient", render: (x) => x.recipient.name },
              { key: "st", header: "Status", render: (x) => <Badge tone="warning">{x.label}</Badge> },
              { key: "cod", header: "Cash to collect", render: (x) => (x.cod_amount_kobo ? `₦${(x.cod_amount_kobo / 100).toLocaleString("en-NG")}` : "—") },
            ]} />
          </Card>
        </>
      )}
    </div>
  );
}
