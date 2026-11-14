"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { formatNaira, nairaToKobo, type MenuItem } from "@gudmeal/api-client";
import { Badge, Button, Card, Dialog, ErrorState, Field, Input, Select, Skeleton, Textarea, Toggle } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Pencil, Plus } from "lucide-react";
import { use, useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { useApi } from "@/lib/api";

const itemSchema = z.object({
  name: z.string().min(1).max(80),
  description: z.string().max(400),
  price_naira: z.coerce.number().positive("Enter a price").max(1_000_000),
  category_id: z.string().min(1),
  kind: z.enum(["main", "combo", "side", "snack", "drink", "dessert", "extra"]),
  serves: z.coerce.number().int().min(1).max(20),
  tags: z.string(),
  allergens: z.string(),
});
type ItemValues = z.input<typeof itemSchema>;
const csv = (s: string) => s.split(",").map((x) => x.trim().toLowerCase()).filter(Boolean);

export default function MenuPage({ params }: { params: Promise<{ rid: string }> }) {
  const { rid } = use(params);
  const api = useApi();
  const qc = useQueryClient();
  const menu = useQuery({ queryKey: ["menu", rid], queryFn: () => api.partner.menu(rid) });
  const [editing, setEditing] = useState<MenuItem | "new" | null>(null);
  const availability = useMutation({
    mutationFn: ({ id, available }: { id: string; available: boolean }) => api.partner.setAvailability(rid, id, available),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["menu", rid] }),
  });

  if (menu.isLoading) return <Skeleton className="h-96" />;
  if (menu.error || !menu.data) return <ErrorState message={(menu.error as Error)?.message ?? "Unavailable"} onRetry={() => menu.refetch()} />;
  const { categories, items } = menu.data;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 className="font-display text-2xl">Menu</h2>
        <Button onClick={() => setEditing("new")}><Plus className="size-4" /> Add item</Button>
      </div>
      {availability.error && <ErrorState message={(availability.error as Error).message} />}
      {categories.map((cat) => {
        const list = items.filter((i) => i.category_id === cat.id);
        return (
          <section key={cat.id} className="space-y-2">
            <h3 className="text-sm font-semibold uppercase tracking-wide text-muted">{cat.name} · {list.length}</h3>
            <div className="divide-y divide-border rounded-lg border border-border bg-surface">
              {list.map((item) => (
                <div key={item.id} className="flex flex-wrap items-center gap-3 p-3">
                  <div className="min-w-0 flex-1">
                    <p className="font-semibold">{item.name} {item.option_group_ids.length > 0 && <Badge>Options</Badge>}</p>
                    <p className="text-sm text-muted">{formatNaira(item.price_kobo)}{item.serves > 1 ? ` · serves ${item.serves}` : ""}</p>
                  </div>
                  <Toggle checked={item.is_available} label={item.is_available ? "Available" : "Sold out"}
                    onChange={(v) => availability.mutate({ id: item.id, available: v })} />
                  <Button variant="ghost" size="sm" onClick={() => setEditing(item)} aria-label={`Edit ${item.name}`}><Pencil className="size-4" /></Button>
                </div>
              ))}
              {list.length === 0 && <p className="p-4 text-sm text-muted">No items in this category yet.</p>}
            </div>
          </section>
        );
      })}
      {editing && <ItemEditor rid={rid} item={editing === "new" ? null : editing} categories={categories} onClose={() => setEditing(null)} />}
    </div>
  );
}

function ItemEditor({ rid, item, categories, onClose }: { rid: string; item: MenuItem | null; categories: { id: string; name: string }[]; onClose: () => void }) {
  const api = useApi();
  const qc = useQueryClient();
  const { register, handleSubmit, formState } = useForm<ItemValues>({
    resolver: zodResolver(itemSchema),
    defaultValues: item ? {
      name: item.name, description: item.description, price_naira: item.price_kobo / 100, category_id: item.category_id,
      kind: item.kind, serves: item.serves, tags: item.tags.join(", "), allergens: item.allergens.join(", "),
    } : { name: "", description: "", price_naira: 0, category_id: categories[0]?.id ?? "", kind: "main", serves: 1, tags: "", allergens: "" },
  });
  const save = useMutation({
    mutationFn: (v: z.output<typeof itemSchema>) => {
      const body = {
        name: v.name, description: v.description, price_kobo: nairaToKobo(v.price_naira), category_id: v.category_id, kind: v.kind,
        serves: v.serves, tags: csv(v.tags), allergens: csv(v.allergens), option_group_ids: item?.option_group_ids ?? [],
        dietary: item?.dietary ?? [], is_available: item?.is_available ?? true, spice_level: item?.spice_level ?? 0,
      };
      return item ? api.partner.updateItem(rid, item.id, body) : api.partner.createItem(rid, body);
    },
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["menu", rid] }); onClose(); },
  });
  const e = formState.errors;
  return (
    <Dialog open onClose={onClose} title={item ? `Edit ${item.name}` : "New menu item"} footer={
      <div className="flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>Cancel</Button>
        <Button onClick={handleSubmit((v) => save.mutate(v as z.output<typeof itemSchema>))} loading={save.isPending}>Save</Button>
      </div>
    }>
      <form className="grid gap-4 sm:grid-cols-2" onSubmit={(ev) => ev.preventDefault()}>
        <Field label="Name" htmlFor="n" error={e.name?.message}><Input id="n" {...register("name")} /></Field>
        <Field label="Price (₦)" htmlFor="p" error={e.price_naira?.message}><Input id="p" type="number" step="50" min="0" {...register("price_naira")} /></Field>
        <div className="sm:col-span-2"><Field label="Description" htmlFor="d"><Textarea id="d" {...register("description")} /></Field></div>
        <Field label="Category" htmlFor="c"><Select id="c" {...register("category_id")}>{categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}</Select></Field>
        <Field label="Type" htmlFor="k">
          <Select id="k" {...register("kind")}>{["main", "combo", "side", "snack", "drink", "dessert", "extra"].map((k) => <option key={k} value={k}>{k}</option>)}</Select>
        </Field>
        <Field label="Serves" htmlFor="s" error={e.serves?.message}><Input id="s" type="number" min={1} max={20} {...register("serves")} /></Field>
        <Field label="Tags" htmlFor="t" hint="Comma separated — helps search"><Input id="t" {...register("tags")} /></Field>
        <div className="sm:col-span-2"><Field label="Allergens" htmlFor="a" hint="e.g. peanuts, shellfish, gluten"><Input id="a" {...register("allergens")} /></Field></div>
        {save.error && <p role="alert" className="text-sm text-danger sm:col-span-2">{(save.error as Error).message}</p>}
      </form>
    </Dialog>
  );
}
