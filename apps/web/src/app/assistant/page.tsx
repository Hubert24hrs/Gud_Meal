import type { Metadata } from "next";
import { Suspense } from "react";
import { Chat } from "./chat";

export const metadata: Metadata = {
  title: "Ask Gud Meal",
  description: "Tell Gud Meal your budget and cravings — we'll plan the best meal and order it with your approval.",
};

export default function AssistantPage() {
  return (
    <Suspense>
      <Chat />
    </Suspense>
  );
}
