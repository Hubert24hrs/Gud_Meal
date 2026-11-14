"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { Button, Card, Field, Input, Select } from "@gudmeal/ui";
import { useMutation } from "@tanstack/react-query";
import { CheckCircle2 } from "lucide-react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { RequireAuth } from "@/components/require-auth";
import { useApi } from "@/lib/api";
import { LAGOS_AREAS } from "@/lib/location";

const schema = z.object({
  business_name: z.string().min(2).max(80),
  cac_number: z.string().min(4, "Enter your CAC registration number").max(20),
  contact_name: z.string().min(2).max(80),
  contact_phone: z.string().min(7).max(20),
  address: z.string().min(5).max(200),
  area: z.string(),
  cuisines: z.string().min(2, "List at least one cuisine"),
  bank_name: z.string().min(2).max(60),
  bank_account_name: z.string().min(2).max(80),
  bank_account_last4: z.string().regex(/^\d{4}$/, "Last 4 digits only"),
});
type Values = z.infer<typeof schema>;

export default function PartnerPage() {
  return (
    <div className="container-page grid gap-10 py-10 lg:grid-cols-2">
      <div className="space-y-4">
        <h1 className="font-display text-4xl">Grow your restaurant with Gud Meal</h1>
        <ul className="space-y-2 text-muted">
          <li>• Reach hungry customers across Lagos — including through our AI concierge.</li>
          <li>• Live order board, menu tools, sales insights and demand forecasts.</li>
          <li>• Transparent commission and weekly settlement statements.</li>
        </ul>
        <p className="text-sm text-muted">We verify every partner (CAC registration and bank details) before going live.
          Full bank account numbers are collected securely by our payment provider, never on this form.</p>
      </div>
      <RequireAuth reason="Create an account first — it becomes your Gud Meal Partner login."><PartnerForm /></RequireAuth>
    </div>
  );
}

function PartnerForm() {
  const api = useApi();
  const { register, handleSubmit, formState } = useForm<Values>({ resolver: zodResolver(schema), defaultValues: { area: LAGOS_AREAS[0]!.name } });
  const submit = useMutation({
    mutationFn: (v: Values) => {
      const area = LAGOS_AREAS.find((a) => a.name === v.area)!;
      return api.applications.restaurant({ ...v, location: area.location, cuisines: v.cuisines.split(",").map((c) => c.trim()).filter(Boolean) });
    },
  });
  if (submit.isSuccess) {
    return (
      <Card className="space-y-3 p-8 text-center">
        <CheckCircle2 className="mx-auto size-12 text-secondary" />
        <h2 className="font-display text-2xl">Application received</h2>
        <p className="text-sm text-muted">Our partnerships team will review your documents within 2 business days.</p>
      </Card>
    );
  }
  const e = formState.errors;
  return (
    <Card className="p-6">
      <form onSubmit={handleSubmit((v) => submit.mutate(v))} className="grid gap-4 sm:grid-cols-2" noValidate>
        <Field label="Restaurant name" htmlFor="bn" error={e.business_name?.message}><Input id="bn" {...register("business_name")} /></Field>
        <Field label="CAC number" htmlFor="cac" error={e.cac_number?.message}><Input id="cac" {...register("cac_number")} /></Field>
        <Field label="Contact name" htmlFor="cn" error={e.contact_name?.message}><Input id="cn" {...register("contact_name")} /></Field>
        <Field label="Contact phone" htmlFor="cp" error={e.contact_phone?.message}><Input id="cp" inputMode="tel" {...register("contact_phone")} /></Field>
        <Field label="Street address" htmlFor="ad" error={e.address?.message}><Input id="ad" {...register("address")} /></Field>
        <Field label="Area" htmlFor="ar"><Select id="ar" {...register("area")}>{LAGOS_AREAS.map((a) => <option key={a.name}>{a.name}</option>)}</Select></Field>
        <Field label="Cuisines" htmlFor="cu" hint="Comma separated" error={e.cuisines?.message}><Input id="cu" placeholder="Nigerian, Grills" {...register("cuisines")} /></Field>
        <Field label="Bank" htmlFor="bk" error={e.bank_name?.message}><Input id="bk" {...register("bank_name")} /></Field>
        <Field label="Account name" htmlFor="an" error={e.bank_account_name?.message}><Input id="an" {...register("bank_account_name")} /></Field>
        <Field label="Account number (last 4)" htmlFor="l4" error={e.bank_account_last4?.message}><Input id="l4" inputMode="numeric" maxLength={4} {...register("bank_account_last4")} /></Field>
        {submit.error && <p role="alert" className="text-sm text-danger sm:col-span-2">{(submit.error as Error).message}</p>}
        <Button type="submit" size="lg" className="sm:col-span-2" loading={submit.isPending}>Submit application</Button>
      </form>
    </Card>
  );
}
