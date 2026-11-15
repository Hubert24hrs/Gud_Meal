import { formatDateTime, type WaybillTracking } from "@gudmeal/api-client";
import { cn } from "@gudmeal/ui";
import { Building2, CalendarClock, Truck } from "lucide-react";

/** Progress of an interstate waybill: steps, expected window, collection point and the scan history. */
export function WaybillTimeline({ data }: { data: WaybillTracking }) {
  const cancelled = data.label === "Cancelled";
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-2 text-sm">
        <Truck className="size-5 text-primary" aria-hidden="true" />
        <span className="font-bold">{data.origin} → {data.destination}</span>
        <span className="rounded-full bg-surface-muted px-2 py-0.5 font-mono text-xs">{data.tracking_code}</span>
      </div>
      {!cancelled && (
        <ol className="grid grid-cols-5 gap-2" aria-label="Shipment progress">
          {data.steps.map((label, i) => (
            <li key={label} className="space-y-1.5">
              <div className={cn("h-1.5 rounded-full", i < data.step || data.delivered ? "bg-secondary" : i === data.step ? "bg-primary" : "bg-border")} />
              <p className={cn("text-[11px] sm:text-xs", i <= data.step ? "font-semibold" : "text-muted")}>{label}</p>
            </li>
          ))}
        </ol>
      )}
      <p className="text-lg font-black">{data.label}</p>
      {!data.delivered && !cancelled && (
        <p className="flex items-center gap-2 text-sm"><CalendarClock className="size-4 text-muted" aria-hidden="true" /> Expected {data.eta_text}</p>
      )}
      {data.collection_point && !data.delivered && !cancelled && (
        <p className="flex items-start gap-2 rounded-lg bg-secondary-soft p-3 text-sm">
          <Building2 className="mt-0.5 size-4 shrink-0 text-secondary" aria-hidden="true" />
          <span>
            Collection point: <strong>{data.collection_point.name}</strong>, {data.collection_point.address} ({data.collection_point.hours}).
            Bring the collection code.
          </span>
        </p>
      )}
      {data.milestones.length > 0 && (
        <ol className="space-y-3 border-l-2 border-border pl-4" aria-label="Shipment history">
          {[...data.milestones].reverse().map((m, i) => (
            <li key={`${m.stage}-${i}`} className="relative">
              <span className={cn("absolute -left-[23px] top-1 size-3 rounded-full", i === 0 ? "bg-primary" : "bg-border")} aria-hidden="true" />
              <p className="text-sm font-semibold">{m.label}</p>
              <p className="text-xs text-muted">{formatDateTime(m.at)}{m.place ? ` · ${m.place}` : ""}</p>
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}
