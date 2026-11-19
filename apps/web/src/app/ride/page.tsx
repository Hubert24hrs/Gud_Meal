"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { Button, Card, Field, Input, Select } from "@gudmeal/ui";
import { useMutation } from "@tanstack/react-query";
import { CheckCircle2 } from "lucide-react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { RequireAuth } from "@/components/require-auth";
import { useApi } from "@/lib/api";

const schema = z.object({
  full_name: z.string().min(2).max(80),
  phone: z.string().min(7).max(20),
  vehicle: z.enum(["motorcycle", "bicycle", "car"]),
  plate_number: z.string().max(20).optional(),
  licence_number: z.string().max(30).optional(),
});
type Values = z.infer<typeof schema>;

export default function RidePage() {
  return (
    <div className="container-page grid gap-10 py-10 lg:grid-cols-2">
      <div className="space-y-4">
        <h1 className="font-display text-4xl">Ride with Yummy Chops</h1>
        <p className="text-muted">Flexible hours, transparent earnings per delivery, and withdrawals to your bank.
          Download the Yummy Chops Rider app after approval to start receiving deliveries.</p>
      </div>
      <RequireAuth reason="Create an account first — it becomes your Yummy Chops Rider login."><RiderForm /></RequireAuth>
    </div>
  );
}

function RiderForm() {
  const api = useApi();
  const { register, handleSubmit, formState } = useForm<Values>({ resolver: zodResolver(schema), defaultValues: { vehicle: "motorcycle" } });
  const submit = useMutation({ mutationFn: (v: Values) => api.applications.rider({ ...v, city: "Lagos" }) });
  if (submit.isSuccess) {
    return (
      <Card className="space-y-3 p-8 text-center">
        <CheckCircle2 className="mx-auto size-12 text-secondary" />
        <h2 className="font-display text-2xl">Thanks for applying</h2>
        <p className="text-sm text-muted">We&apos;ll verify your identity and vehicle documents and contact you.</p>
      </Card>
    );
  }
  const e = formState.errors;
  return (
    <Card className="p-6">
      <form onSubmit={handleSubmit((v) => submit.mutate(v))} className="grid gap-4" noValidate>
        <Field label="Full name" htmlFor="fn" error={e.full_name?.message}><Input id="fn" {...register("full_name")} /></Field>
        <Field label="Phone" htmlFor="ph" error={e.phone?.message}><Input id="ph" inputMode="tel" {...register("phone")} /></Field>
        <Field label="Vehicle" htmlFor="vh">
          <Select id="vh" {...register("vehicle")}><option value="motorcycle">Motorcycle</option><option value="bicycle">Bicycle</option><option value="car">Car</option></Select>
        </Field>
        <Field label="Plate number" htmlFor="pn"><Input id="pn" {...register("plate_number")} /></Field>
        <Field label="Driver's licence number" htmlFor="ln"><Input id="ln" {...register("licence_number")} /></Field>
        {submit.error && <p role="alert" className="text-sm text-danger">{(submit.error as Error).message}</p>}
        <Button type="submit" size="lg" loading={submit.isPending}>Apply to ride</Button>
      </form>
    </Card>
  );
}
