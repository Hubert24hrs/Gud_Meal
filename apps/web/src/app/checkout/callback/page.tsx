"use client";

import { Button, Card, Spinner } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { CheckCircle2, XCircle } from "lucide-react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense } from "react";
import { RequireAuth } from "@/components/require-auth";
import { useApi } from "@/lib/api";

export default function CallbackPage() {
  return (
    <RequireAuth>
      <Suspense><Callback /></Suspense>
    </RequireAuth>
  );
}

function Callback() {
  const params = useSearchParams();
  const api = useApi();
  // Paystack appends `reference`/`trxref`; Flutterwave appends `tx_ref`.
  const reference = params.get("reference") ?? params.get("trxref") ?? params.get("tx_ref");
  const orderId = params.get("order_id");
  const isTopUp = params.get("purpose") === "wallet_topup";

  // Never trust the redirect: ask the server to verify with the provider.
  const verify = useQuery({
    queryKey: ["verify", reference],
    enabled: Boolean(reference),
    queryFn: () => api.payments.verify(reference!),
    refetchInterval: (q) => (q.state.data && ["pending", "initialized"].includes(q.state.data.status) ? 3000 : false),
  });

  const status = verify.data?.status;
  return (
    <div className="container-page grid place-items-center py-20">
      <Card className="w-full max-w-md space-y-4 p-8 text-center">
        {!reference ? (
          <p>Missing payment reference.</p>
        ) : verify.isLoading || status === "pending" || status === "initialized" ? (
          <>
            <Spinner className="mx-auto size-10 text-primary" />
            <h1 className="font-display text-2xl">Confirming your payment…</h1>
            <p className="text-sm text-muted">We&apos;re checking with the payment provider. This usually takes a few seconds.</p>
          </>
        ) : status === "succeeded" ? (
          <>
            <CheckCircle2 className="mx-auto size-12 text-secondary" />
            {isTopUp || verify.data?.purpose === "wallet_topup" ? (
              <>
                <h1 className="font-display text-2xl">Wallet topped up</h1>
                <p className="text-sm text-muted">The money is in your Gud Meal wallet. Pay for orders in one tap.</p>
                <Link href="/wallet"><Button size="lg" block>Go to my wallet</Button></Link>
              </>
            ) : (
              <>
                <h1 className="font-display text-2xl">Payment confirmed</h1>
                <p className="text-sm text-muted">Your order has been sent to the restaurant.</p>
                <Link href={`/orders/${verify.data!.order_id}`}><Button size="lg" block>Track my order</Button></Link>
              </>
            )}
          </>
        ) : (
          <>
            <XCircle className="mx-auto size-12 text-danger" />
            <h1 className="font-display text-2xl">Payment not completed</h1>
            <p className="text-sm text-muted">{verify.data?.failure_reason ?? "The payment was not successful. You have not been charged."}</p>
            {orderId && <Link href={`/orders/${orderId}`}><Button variant="outline" block>View order</Button></Link>}
            {isTopUp && <Link href="/wallet"><Button variant="outline" block>Back to my wallet</Button></Link>}
          </>
        )}
      </Card>
    </div>
  );
}
