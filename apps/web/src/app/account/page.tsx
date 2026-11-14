"use client";

import { Button, Card, Field, Input, Skeleton, Toggle } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useEffect, useState } from "react";
import { RequireAuth } from "@/components/require-auth";
import { useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";

export default function AccountPage() {
  return <RequireAuth><Account /></RequireAuth>;
}

const split = (s: string) => s.split(",").map((x) => x.trim()).filter(Boolean);

function Account() {
  const api = useApi();
  const qc = useQueryClient();
  const { user, signOut } = useAuth();
  const profile = useQuery({ queryKey: ["profile"], queryFn: () => api.me.profile() });
  const addresses = useQuery({ queryKey: ["addresses"], queryFn: () => api.me.addresses() });
  const [allergens, setAllergens] = useState("");
  const [dietary, setDietary] = useState("");
  const [personalise, setPersonalise] = useState(true);

  useEffect(() => {
    if (!profile.data) return;
    setAllergens(profile.data.allergens.join(", "));
    setDietary(profile.data.dietary.join(", "));
    setPersonalise(profile.data.personalisation_consent);
  }, [profile.data]);

  const save = useMutation({
    mutationFn: () => api.me.updateProfile({ allergens: split(allergens), dietary: split(dietary), personalisation_consent: personalise }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["profile"] }),
  });
  const remove = useMutation({ mutationFn: (id: string) => api.me.deleteAddress(id), onSuccess: () => qc.invalidateQueries({ queryKey: ["addresses"] }) });

  return (
    <div className="container-page max-w-3xl space-y-6 py-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-display text-3xl">Your account</h1>
          <p className="text-sm text-muted">{user?.displayName ?? user?.email}</p>
        </div>
        <Button variant="outline" onClick={() => signOut()}>Sign out</Button>
      </div>
      <div className="flex gap-3 text-sm">
        <Link href="/orders" className="font-semibold text-primary">Order history →</Link>
      </div>
      <Card className="space-y-4 p-5">
        <h2 className="font-semibold">Food preferences</h2>
        {profile.isLoading ? <Skeleton className="h-28" /> : (
          <>
            <Field label="Allergies" htmlFor="allergens" hint="Comma separated, e.g. peanuts, shellfish. Gud Meal's assistant never recommends these.">
              <Input id="allergens" value={allergens} onChange={(e) => setAllergens(e.target.value)} />
            </Field>
            <Field label="Dietary preferences" htmlFor="dietary" hint="e.g. vegetarian, halal">
              <Input id="dietary" value={dietary} onChange={(e) => setDietary(e.target.value)} />
            </Field>
            <Toggle checked={personalise} onChange={setPersonalise} label="Personalise recommendations using my orders and preferences" />
            <div className="flex items-center gap-3">
              <Button onClick={() => save.mutate()} loading={save.isPending}>Save preferences</Button>
              {save.isSuccess && <span className="text-sm text-secondary">Saved</span>}
            </div>
          </>
        )}
      </Card>
      <Card className="space-y-3 p-5">
        <h2 className="font-semibold">Saved addresses</h2>
        {addresses.data?.length ? addresses.data.map((a) => (
          <div key={a.id} className="flex items-center justify-between rounded-md border border-border p-3 text-sm">
            <span>{a.label && <strong>{a.label} · </strong>}{a.line1}, {a.area}</span>
            <button className="text-danger" onClick={() => remove.mutate(a.id)}>Remove</button>
          </div>
        )) : <p className="text-sm text-muted">Addresses you use at checkout are saved here.</p>}
      </Card>
      <Card className="space-y-2 p-5 text-sm">
        <h2 className="font-semibold">Your data</h2>
        <p className="text-muted">Under the Nigeria Data Protection Act you can request a copy of your data or ask us to delete your account.</p>
        <Button variant="outline" size="sm" onClick={async () => {
          const data = await api.request<unknown>("GET", "/v1/me/export");
          const url = URL.createObjectURL(new Blob([JSON.stringify(data, null, 2)], { type: "application/json" }));
          const a = Object.assign(document.createElement("a"), { href: url, download: "gudmeal-my-data.json" });
          a.click();
          URL.revokeObjectURL(url);
        }}>Download my data</Button>
      </Card>
    </div>
  );
}
