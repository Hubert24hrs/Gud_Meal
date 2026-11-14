import { Logo } from "@gudmeal/ui";
import Link from "next/link";

export function Footer() {
  return (
    <footer className="mt-16 border-t border-border bg-surface">
      <div className="container-page grid gap-8 py-10 sm:grid-cols-2 lg:grid-cols-4">
        <div className="space-y-3">
          <Logo />
          <p className="max-w-xs text-sm text-muted">Discover. Order. Eat. Lagos&apos; favourite kitchens, delivered — with an AI that plans to your budget.</p>
        </div>
        <FooterCol title="Order" links={[["Restaurants", "/restaurants"], ["Ask Gud Meal", "/assistant"], ["My orders", "/orders"]]} />
        <FooterCol title="Partner" links={[["Add your restaurant", "/partner-with-us"], ["Ride with Gud Meal", "/ride"]]} />
        <FooterCol title="Help" links={[["Help centre", "/help"], ["Privacy", "/help#privacy"], ["Terms", "/help#terms"]]} />
      </div>
      <div className="container-page border-t border-border py-4 text-xs text-muted">
        © {new Date().getFullYear()} Gud Meal. Prices in Naira (₦) include VAT where applicable.
      </div>
    </footer>
  );
}

function FooterCol({ title, links }: { title: string; links: [string, string][] }) {
  return (
    <div>
      <p className="mb-3 text-sm font-semibold">{title}</p>
      <ul className="space-y-2 text-sm text-muted">
        {links.map(([label, href]) => (
          <li key={href}><Link href={href} className="hover:text-text">{label}</Link></li>
        ))}
      </ul>
    </div>
  );
}
