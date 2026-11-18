import Link from "next/link";

export default function NotFound() {
  return (
    <div className="container-page flex flex-col items-center gap-4 py-24 text-center">
      <p className="font-display text-6xl text-primary">404</p>
      <h1 className="font-display text-2xl">This page went out for delivery</h1>
      <Link href="/" className="font-semibold text-primary underline-offset-2 hover:underline">Back to GudMeals</Link>
    </div>
  );
}
