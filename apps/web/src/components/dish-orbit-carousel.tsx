"use client";

import { formatNaira, type DiscoverDish } from "@gudmeal/api-client";
import { cn } from "@gudmeal/ui";
import Link from "next/link";
import {
  useCallback,
  useEffect,
  useId,
  useLayoutEffect,
  useRef,
  useState,
  type CSSProperties,
  type KeyboardEvent,
  type MouseEvent as ReactMouseEvent,
  type PointerEvent as ReactPointerEvent,
} from "react";
import { plateImage } from "./plate-art";
import "./dish-orbit-carousel.css";

// ================================================================================================
// Dish Orbit Carousel for the website's Discover page: the web twin of the mobile app's Discover
// carousel (mobile/customer/lib/features/discover/dish_orbit_carousel.dart), both ported from the
// "dish orbit" kitchen-display carousel (React + GSAP). The plated dish sits centre stage; changing
// dish swings it out over the top on a wide orbit while the next plate swings in from the other side.
// The two-weight title wipes out and back in (thin line from the right, heavy line from the left),
// the kitchen card and its coloured rating badge cross-fade, and a pastel arc behind the scene
// stretches along the orbit and takes the dish's colour. It moves on by itself (pausable, and never
// while hovered, focused, off screen or with reduced motion), and with the pager, thumbnails, arrow
// keys and swipes. Unlike the original it does not take over the page scroll, so the stores below
// stay one scroll away. No animation library: one timeline (GSAP power2 = cubic, power3 = quartic)
// written straight to the DOM each frame, so React renders only when a dish changes.
// ================================================================================================

// ------------------------------------------------------------------ pure helpers (unit tested)
export function wrapIndex(i: number, n: number): number {
  if (n <= 0) return 0;
  return ((Math.round(i) % n) + n) % n;
}

/** Which way to swing when jumping from one dish to another: the shorter way round (1 = forwards). */
export function stepDirection(from: number, to: number, n: number): 1 | -1 {
  if (n <= 0) return 1;
  const forward = (((to - from) % n) + n) % n;
  return forward <= n - forward ? 1 : -1;
}

/** First thumbnail shown in the strip window, keeping the current one in view. */
export function stripStart(index: number, n: number, visible: number): number {
  if (n <= visible) return 0;
  return Math.max(0, Math.min(index - 1, n - visible));
}

/** Title font size so a line of `chars` characters fits `width` px at `em` average glyph width. */
export function fitSize(chars: number, max: number, width: number, em: number): number {
  return Math.min(max, width / (Math.max(1, chars) * em));
}

/**
 * The pastel band: a thick stroke along the plates' orbit circle, tapering at both ends.
 * Angles in degrees, screen space (0 = right, 90 = straight down).
 */
export function arcPath(a0: number, a1: number, cx: number, cy: number, r: number, w: number, steps = 48): string {
  const outer: string[] = [];
  const inner: string[] = [];
  for (let i = 0; i <= steps; i++) {
    const t = i / steps;
    const a = ((a0 + (a1 - a0) * t) * Math.PI) / 180;
    const h = (w / 2) * Math.pow(Math.sin(Math.PI * t), 0.45);
    const c = Math.cos(a);
    const s = Math.sin(a);
    outer.push((cx + c * (r + h)).toFixed(1) + " " + (cy + s * (r + h)).toFixed(1));
    inner.push((cx + c * (r - h)).toFixed(1) + " " + (cy + s * (r - h)).toFixed(1));
  }
  return "M" + outer.join("L") + "L" + inner.reverse().join("L") + "Z";
}

/** Where the band rests for each dish, as [start, end] angles along the orbit. */
export const ARC_REST: readonly (readonly [number, number])[] = [[50, 98], [46, 124], [60, 126], [40, 100]];
export const arcRest = (index: number) => ARC_REST[wrapIndex(index, ARC_REST.length)]!;

/** The band mid-swap: it stretches to trail between the outgoing and incoming plate. */
export const ARC_SWEEP = [38, 146] as const;

/** Pastel accents for the rating badge and the band, one per dish position (as in the app). */
export const DISH_ACCENTS = ["#F6A37C", "#F2A6C6", "#BCD98E", "#F5D26A", "#9FCBE8"] as const;
export const accentFor = (index: number) => DISH_ACCENTS[wrapIndex(index, DISH_ACCENTS.length)]!;

/** Mixes two #rrggbb colours (t = 0 gives `a`). */
export function mixHex(a: string, b: string, t: number): string {
  const ch = (h: string, i: number) => parseInt(h.slice(1 + i * 2, 3 + i * 2), 16);
  const out = [0, 1, 2].map((i) => Math.round(ch(a, i) + (ch(b, i) - ch(a, i)) * t).toString(16).padStart(2, "0"));
  return "#" + out.join("");
}

/**
 * Splits a dish name into the thin first line and the heavy second line ("Party" / "Jollof Rice").
 * Drops portion notes in brackets, balances the two lines, never starts the heavy line with "&".
 */
export function splitTitle(name: string): { thin: string; heavy: string } {
  const clean = name.replace(/\s*\([^)]*\)/g, "").trim();
  const words = clean.split(/\s+/).filter(Boolean);
  if (words.length < 2) return { thin: "", heavy: clean };
  const connectors = new Set(["&", "and", "with", "+", "n"]);
  let thin: string | null = null;
  let heavy: string | null = null;
  let best = Number.MAX_SAFE_INTEGER;
  for (let k = 1; k < words.length; k++) {
    if (connectors.has(words[k]!.toLowerCase())) continue;
    const a = words.slice(0, k).join(" ").replace(/,$/, "");
    const b = words.slice(k).join(" ");
    const score = Math.max(a.length, b.length);
    if (score <= best) {
      // ties go to the later split: a shorter heavy line reads bigger
      best = score;
      thin = a;
      heavy = b;
    }
  }
  return { thin: thin ?? words[0]!, heavy: heavy ?? words.slice(1).join(" ") };
}

/** What's in it, for the "Ingredients" tab: tags, dietary notes and allergens, de-duplicated. */
export function dishHighlights(d: Pick<DiscoverDish, "tags" | "dietary" | "allergens">): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const raw of [...d.tags, ...d.dietary, ...d.allergens.map((a) => `contains ${a}`)]) {
    const t = raw.trim();
    if (t && !seen.has(t.toLowerCase())) {
      seen.add(t.toLowerCase());
      out.push(t);
    }
  }
  return out;
}

/** The line under the kitchen's name: area, open state, and the delivery time and fee the API worked out. */
export function dishDetails(d: DiscoverDish): string {
  const parts: string[] = [];
  if (d.area) parts.push(d.area);
  if (!d.is_open) parts.push("Closed now");
  else if (!d.is_accepting_orders) parts.push("Paused");
  if (!d.is_available) parts.push("Sold out");
  if (d.delivers_to_location === false) {
    parts.push("Outside your delivery area");
  } else {
    if (d.eta_minutes != null && d.is_open) parts.push(`${d.eta_minutes} min`);
    if (d.delivery_fee_kobo != null) parts.push(`${formatNaira(d.delivery_fee_kobo)} delivery`);
  }
  return parts.join(" · ");
}

/** 980 -> "980", 1500 -> "1.5k", 12_400 -> "12k". */
export function compactCount(n: number): string {
  if (n < 1000) return String(n);
  return (n / 1000).toFixed(n >= 10_000 ? 0 : 1).replace(/\.0$/, "") + "k";
}

export const dishKey = (d: Pick<DiscoverDish, "restaurant_id" | "item_id">) => `${d.restaurant_id}/${d.item_id}`;
const listKey = (list: DiscoverDish[]) => list.map(dishKey).join("|");

// ------------------------------------------------------------------ the timeline
/** Timeline length in seconds (the last tween ends at 1.45 s). */
export const TIMELINE = 1.45;
/** Degrees the plate travels round the orbit's pivot. */
export const SWING = 50;
const ROWS = 5;

// The plates' orbit and the band, in the 960 x 520 design canvas (pivot far above the canvas).
const ORBIT_X = 299;
const ORBIT_Y = -450;
const ORBIT_R = 650;
const BAND_W = 118;
const THUMB = 118;
const VISIBLE_THUMBS = 4;
const HOLD_MS = 12_000;

const clamp01 = (x: number) => Math.min(1, Math.max(0, x));
const lerp = (a: number, b: number, t: number) => a + (b - a) * t;
type Ease = (x: number) => number;
const quadIn: Ease = (x) => x * x;
const quadOut: Ease = (x) => 1 - (1 - x) * (1 - x);
const quadInOut: Ease = (x) => (x < 0.5 ? 2 * x * x : 1 - Math.pow(-2 * x + 2, 2) / 2);
const cubicIn: Ease = (x) => x * x * x;
const cubicOut: Ease = (x) => 1 - Math.pow(1 - x, 3);
const cubicInOut: Ease = (x) => (x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2);
const quartOut: Ease = (x) => 1 - Math.pow(1 - x, 4);
const seg = (t: number, start: number, duration: number, ease: Ease) => ease(clamp01((t - start) / duration));

export interface Frame {
  /** Plates: rotation round the orbit pivot, in degrees, and whether each is drawn. */
  outRotation: number; outPlate: boolean; inRotation: number; inPlate: boolean;
  /** Titles: thin/heavy are the fraction wiped away (0 = fully shown). */
  outHead: boolean; outEye: number; outThin: number; outHeavy: number;
  inHead: boolean; inEye: number; inEyeY: number; inThin: number; inHeavy: number;
  /** Card: the outgoing body fades up and away; the incoming rows rise in one after another. */
  outBody: number; outBodyY: number; inBody: boolean; rows: { opacity: number; y: number }[];
  /** Band angles and how far its colour has moved from the old dish's accent to the new one's. */
  band: { a0: number; a1: number; tint: number };
}

/** Every animated value `t` seconds into a swap from dish position `from` to `to` (dir 1 = forwards). */
export function frameAt(t: number, dir: 1 | -1, from: number, to: number): Frame {
  const restFrom = arcRest(from);
  const rest = arcRest(to);
  let a0: number;
  let a1: number;
  if (t < 0.6) {
    const p = seg(t, 0, 0.6, cubicInOut);
    a0 = lerp(restFrom[0], ARC_SWEEP[0], p);
    a1 = lerp(restFrom[1], ARC_SWEEP[1], p);
  } else {
    const p = seg(t, 0.6, 0.85, quartOut);
    a0 = lerp(ARC_SWEEP[0], rest[0], p);
    a1 = lerp(ARC_SWEEP[1], rest[1], p);
  }
  const eyeIn = seg(t, 0.55, 0.4, cubicOut);
  const outFade = seg(t, 0.05, 0.3, quadIn);
  return {
    outRotation: SWING * dir * seg(t, 0, 0.62, cubicIn),
    outPlate: t < 0.62,
    inRotation: -SWING * dir * (1 - seg(t, 0.3, 0.95, quartOut)),
    inPlate: t >= 0.3,
    outHead: t < 0.5,
    outEye: 1 - seg(t, 0, 0.25, quadOut),
    outThin: seg(t, 0, 0.42, cubicIn),
    outHeavy: seg(t, 0.06, 0.42, cubicIn),
    inHead: t >= 0.5,
    inEye: eyeIn,
    inEyeY: 6 * (1 - eyeIn),
    inThin: 1 - seg(t, 0.55, 0.7, quartOut),
    inHeavy: 1 - seg(t, 0.62, 0.7, quartOut),
    outBody: 1 - outFade,
    outBodyY: -6 * outFade,
    inBody: t >= 0.4,
    rows: Array.from({ length: ROWS }, (_, k) => {
      const p = seg(t, 0.4 + 0.06 * k, 0.5, cubicOut);
      return { opacity: p, y: 10 * (1 - p) };
    }),
    band: { a0, a1, tint: seg(t, 0.1, 1.1, quadInOut) },
  };
}

type Role = "out" | "in";

/** Writes a frame to the DOM (or the resting state when `f` is null). Leftovers of an interrupted swap are overwritten. */
function applyFrame(root: HTMLElement, band: SVGPathElement | null, f: Frame | null, from: number, to: number) {
  const part = (role: Role, name: string) => root.querySelector<HTMLElement>(`[data-role="${role}"][data-part="${name}"]`);
  const show = (el: HTMLElement | null, on: boolean) => {
    if (el) el.style.visibility = on ? "" : "hidden";
  };

  const outPlate = part("out", "plate");
  if (outPlate) {
    outPlate.style.transform = `rotate(${(f?.outRotation ?? 0).toFixed(2)}deg)`;
    show(outPlate, f ? f.outPlate : false);
  }
  const inPlate = part("in", "plate");
  if (inPlate) {
    inPlate.style.transform = f && f.inRotation !== 0 ? `rotate(${f.inRotation.toFixed(2)}deg)` : "";
    show(inPlate, f ? f.inPlate : true);
  }

  const head = (el: HTMLElement | null, visible: boolean, eye: number, eyeY: number, thin: number, heavy: number) => {
    if (!el) return;
    show(el, visible);
    const e = el.querySelector<HTMLElement>(".dsh-eye");
    if (e) {
      e.style.opacity = eye >= 1 ? "" : eye.toFixed(3);
      e.style.transform = eyeY ? `translateY(${eyeY.toFixed(2)}px)` : "";
    }
    const t1 = el.querySelector<HTMLElement>(".dsh-t1");
    if (t1) t1.style.clipPath = thin > 0 ? `inset(0% 0% 0% ${(thin * 100).toFixed(2)}%)` : "";
    const t2 = el.querySelector<HTMLElement>(".dsh-t2");
    if (t2) t2.style.clipPath = heavy > 0 ? `inset(0% ${(heavy * 100).toFixed(2)}% 0% 0%)` : "";
  };
  if (f) {
    head(part("out", "head"), f.outHead, f.outEye, 0, f.outThin, f.outHeavy);
    head(part("in", "head"), f.inHead, f.inEye, f.inEyeY, f.inThin, f.inHeavy);
  } else {
    head(part("out", "head"), false, 1, 0, 0, 0);
    head(part("in", "head"), true, 1, 0, 0, 0);
  }
  show(part("out", "acts"), f ? f.outHead : false);
  show(part("in", "acts"), f ? f.inHead : true);

  const outBody = part("out", "body");
  if (outBody) {
    outBody.style.opacity = (f?.outBody ?? 0).toFixed(3);
    outBody.style.transform = f?.outBodyY ? `translateY(${f.outBodyY.toFixed(2)}px)` : "";
    show(outBody, f ? f.outBody > 0 : false);
    outBody.querySelectorAll<HTMLElement>("[data-row]").forEach((row) => {
      row.style.opacity = "";
      row.style.transform = "";
    });
  }
  const inBody = part("in", "body");
  if (inBody) {
    show(inBody, f ? f.inBody : true);
    inBody.style.opacity = "";
    inBody.style.transform = "";
    inBody.querySelectorAll<HTMLElement>("[data-row]").forEach((row, k) => {
      const r = f?.rows[Math.min(k, ROWS - 1)];
      row.style.opacity = r && r.opacity < 1 ? r.opacity.toFixed(3) : "";
      row.style.transform = r && r.y > 0.01 ? `translateY(${r.y.toFixed(2)}px)` : "";
    });
  }

  if (band) {
    const rest = arcRest(to);
    const a0 = f ? f.band.a0 : rest[0];
    const a1 = f ? f.band.a1 : rest[1];
    band.setAttribute("d", arcPath(a0, a1, ORBIT_X, ORBIT_Y, ORBIT_R, BAND_W));
    band.setAttribute("fill", f ? mixHex(accentFor(from), accentFor(to), f.band.tint) : accentFor(to));
  }
}

/** Shrinks a title line that still overflows its box after the size estimate (long names, wide fonts). */
function fitTitles(root: HTMLElement) {
  root.querySelectorAll<HTMLElement>(".dsh-t1, .dsh-t2").forEach((el) => {
    el.style.fontSize = "";
    const box = el.clientWidth;
    const need = el.scrollWidth;
    if (box > 0 && need > box) {
      const size = parseFloat(getComputedStyle(el).fontSize);
      if (size > 0) el.style.fontSize = `${Math.floor(size * (box / need) * 0.97 * 10) / 10}px`;
    }
  });
}

function useReducedMotion(): boolean {
  const [reduced, setReduced] = useState(false);
  useEffect(() => {
    if (typeof window === "undefined" || typeof window.matchMedia !== "function") return;
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    const on = () => setReduced(mq.matches);
    on();
    mq.addEventListener?.("change", on);
    return () => mq.removeEventListener?.("change", on);
  }, []);
  return reduced;
}

// ------------------------------------------------------------------ icons
const Icon = {
  gudy: (
    <svg className="dsh-ico" viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 3.5 13.9 9 19.5 11 13.9 13 12 18.5 10.1 13 4.5 11 10.1 9z" />
      <path d="M18.5 3.5v3M17 5h3" />
    </svg>
  ),
  order: <svg className="dsh-ico dsh-fill" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 5 3 15h18zM3 18h18v2.5H3z" /></svg>,
  up: (
    <svg className="dsh-ico" viewBox="0 0 24 24" aria-hidden="true">
      <path d="M7 10v10H3.5V10zM7 10l4-7c1.6 0 2.6 1.2 2.2 2.8L12.6 9H19a2 2 0 0 1 2 2.3l-1.3 7A2 2 0 0 1 17.7 20H7" />
    </svg>
  ),
  down: (
    <svg className="dsh-ico" viewBox="0 0 24 24" aria-hidden="true">
      <path d="M17 14V4h3.5v10zM17 14l-4 7c-1.6 0-2.6-1.2-2.2-2.8l.6-3.2H5a2 2 0 0 1-2-2.3l1.3-7A2 2 0 0 1 6.3 4H17" />
    </svg>
  ),
  pause: <svg className="dsh-ico dsh-fill" viewBox="0 0 24 24" aria-hidden="true"><path d="M6 4h4v16H6zM14 4h4v16h-4z" /></svg>,
  play: <svg className="dsh-ico dsh-fill" viewBox="0 0 24 24" aria-hidden="true"><path d="M7 4v16l13-8z" /></svg>,
  star: <svg viewBox="0 0 24 24" aria-hidden="true"><path d="m12 2.5 2.9 6 6.6.8-4.9 4.6 1.3 6.6L12 17.2l-5.9 3.3 1.3-6.6-4.9-4.6 6.6-.8z" /></svg>,
};

// ------------------------------------------------------------------ pieces
/** The kitchen's photo when it has uploaded one, otherwise the illustrated plate. */
function PlateImage({ dish, size }: { dish: DiscoverDish; size: number }) {
  const [failed, setFailed] = useState(false);
  const photo = dish.image_url && !failed ? dish.image_url : null;
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={photo ?? plateImage(dish.art, dish.name)}
      alt=""
      width={size}
      height={size}
      draggable={false}
      decoding="async"
      className={photo ? "dsh-photo" : undefined}
      onError={photo ? () => setFailed(true) : undefined}
    />
  );
}

function Head({ role, dish, position }: { role: Role; dish: DiscoverDish; position: number }) {
  const { thin, heavy } = splitTitle(dish.name);
  const size = (text: string, desktopMax: number, mobileMax: number, em: number): CSSProperties =>
    ({
      "--fs-d": `${fitSize(text.length, desktopMax, 322, em).toFixed(1)}px`,
      "--fs-m": `min(${mobileMax}px, calc((100cqw - 72px) / ${(Math.max(1, text.length) * em).toFixed(2)}))`,
    }) as CSSProperties;
  return (
    <div className="dsh-hd" data-role={role} data-part="head" inert={role === "out" || undefined}>
      <p className="dsh-eye">{dish.eyebrow || `#${position + 1} Most loved dish`}</p>
      <h3 className="dsh-h">
        {thin && <span className="dsh-t1" style={size(thin, 56, 44, 0.62)}>{thin}</span>}{thin && " "}
        <span className="dsh-t2" style={size(heavy, 62, 48, 0.74)}>{heavy}</span>
      </h3>
    </div>
  );
}

function Actions({ role, dish, orderHref, askHref }: {
  role: Role; dish: DiscoverDish; orderHref: (d: DiscoverDish) => string; askHref?: (d: DiscoverDish) => string;
}) {
  const price = formatNaira(dish.price_kobo);
  return (
    <div className="dsh-act" data-role={role} data-part="acts" inert={role === "out" || undefined}>
      {askHref && (
        <Link className="dsh-link" href={askHref(dish)}>
          {Icon.gudy}Ask Yummy <span className="sr-only">about {dish.name}</span>
        </Link>
      )}
      <Link className="dsh-link" href={orderHref(dish)}>
        {Icon.order}Order food · {price} <span className="sr-only">for {dish.name} from {dish.restaurant_name}</span>
      </Link>
    </div>
  );
}

function Body({ role, dish, position, ingredients, liked, disliked, onLike, onDislike }: {
  role: Role; dish: DiscoverDish; position: number; ingredients: boolean; liked: boolean; disliked: boolean;
  onLike: () => void; onDislike: () => void;
}) {
  const highlights = dishHighlights(dish);
  const rating = dish.rating.toFixed(1);
  return (
    <div className="dsh-body" data-role={role} data-part="body" inert={role === "out" || undefined}>
      <div data-row className="dsh-rate" role="img" aria-label={`Kitchen rated ${rating} out of 5`}>
        <span className="dsh-num" aria-hidden="true">{rating}</span>
        <span className="dsh-badge" style={{ background: accentFor(position) }} aria-hidden="true">
          {Icon.star}
          <span className="dsh-num">{rating}</span>
        </span>
      </div>
      <p data-row className="dsh-chef">{dish.restaurant_name}</p>
      <p data-row className="dsh-kit">{dishDetails(dish) || " "}</p>
      <div data-row>
        {ingredients && highlights.length > 0 ? (
          <ul className="dsh-ing" aria-label={`What's in ${dish.name}`}>{highlights.map((h) => <li key={h}>{h}</li>)}</ul>
        ) : (
          <p className="dsh-desc">{dish.description || `${dish.name}, freshly made by ${dish.restaurant_name}.`}</p>
        )}
      </div>
      <div data-row className="dsh-react">
        <button type="button" className="dsh-btn dsh-like" aria-pressed={liked} onClick={onLike}>
          {Icon.up}<span className="sr-only">Like {dish.name},</span> {compactCount(dish.likes)} orders
        </button>
        <button type="button" className="dsh-btn dsh-meh" aria-pressed={disliked} aria-label="Not for me" onClick={onDislike}>
          {Icon.down}
        </button>
      </div>
    </div>
  );
}

// ------------------------------------------------------------------ the carousel
type Shown = { dish: DiscoverDish; position: number };
interface View { list: DiscoverDish[]; index: number; out: Shown | null; dir: 1 | -1; run: number }

export type DishOrbitCarouselProps = {
  dishes: DiscoverDish[];
  /** Where "Order food" (and the plate) goes. */
  orderHref: (dish: DiscoverDish) => string;
  /** Where "Ask Yummy" goes; leave out to hide the button. */
  askHref?: (dish: DiscoverDish) => string;
  /** Moves on to the next dish every so often (ms); 0 turns it off. */
  autoPlayMs?: number;
  label?: string;
  className?: string;
};

export function DishOrbitCarousel({ dishes, orderHref, askHref, autoPlayMs = 6000, label = "Featured dishes", className }: DishOrbitCarouselProps) {
  const reduced = useReducedMotion();
  const reducedRef = useRef(reduced);
  const [view, setView] = useState<View>(() => ({ list: dishes, index: 0, out: null, dir: 1, run: 0 }));
  const [ingredients, setIngredients] = useState(false);
  const [liked, setLiked] = useState<ReadonlySet<string>>(() => new Set());
  const [disliked, setDisliked] = useState<ReadonlySet<string>>(() => new Set());
  const [paused, setPaused] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const bandRef = useRef<SVGPathElement>(null);
  const animating = useRef(false);
  const holdUntil = useRef(0);
  const hovered = useRef(false);
  const focused = useRef(false);
  const onScreen = useRef(true);
  const swipe = useRef<{ x: number; y: number } | null>(null);
  const swiped = useRef(false);
  const panelId = useId();

  // A different list (another section or area): the current plate swings away and the new first dish swings in.
  if (view.list !== dishes) {
    if (listKey(view.list) === listKey(dishes)) {
      setView({ ...view, list: dishes });
    } else {
      const prev = view.list.length ? view.list[wrapIndex(view.index, view.list.length)]! : null;
      const animate = !reduced && prev !== null && dishes.length > 0 && dishKey(prev) !== dishKey(dishes[0]!);
      setView({ list: dishes, index: 0, out: animate ? { dish: prev, position: view.index } : null, dir: 1, run: view.run + 1 });
    }
  }

  useEffect(() => {
    reducedRef.current = reduced;
  }, [reduced]);

  const go = useCallback((target: number | ((index: number) => number), dir?: 1 | -1, byUser = true) => {
    if (byUser) holdUntil.current = Date.now() + HOLD_MS;
    setView((v) => {
      const n = v.list.length;
      if (n < 2) return v;
      const next = wrapIndex(typeof target === "function" ? target(v.index) : target, n);
      if (next === v.index) return v;
      // Like GSAP's progress(1).kill(): an interrupted swap snaps to its end before the next one starts.
      const out = reducedRef.current ? null : { dish: v.list[v.index]!, position: v.index };
      return { ...v, index: next, dir: dir ?? stepDirection(v.index, next, n), out, run: v.run + 1 };
    });
  }, []);
  const step = useCallback((d: 1 | -1, byUser = true) => go((i) => i + d, d, byUser), [go]);

  // Fit the 960 x 520 design canvas to the root (wide layout), and keep long titles inside their box.
  useLayoutEffect(() => {
    const root = rootRef.current;
    if (!root) return;
    const fit = () => {
      const w = root.clientWidth;
      const h = root.clientHeight;
      if (w > 0 && h > 0) root.style.setProperty("--dsh-s", String(Math.min(w / 960, h / 520, 1.6)));
      fitTitles(root);
    };
    fit();
    if (typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(fit);
    ro.observe(root);
    return () => ro.disconnect();
  }, []);

  // One timeline per swap, written straight to the DOM.
  const { out, dir, index, run } = view;
  useLayoutEffect(() => {
    const root = rootRef.current;
    if (!root) return;
    fitTitles(root);
    const from = out ? out.position : index;
    if (!out) {
      animating.current = false;
      applyFrame(root, bandRef.current, null, from, index);
      return;
    }
    animating.current = true;
    applyFrame(root, bandRef.current, frameAt(0, dir, from, index), from, index);
    const start = performance.now();
    let raf = requestAnimationFrame(function tick(now: number) {
      const t = Math.min(TIMELINE, Math.max(0, (now - start) / 1000));
      applyFrame(root, bandRef.current, frameAt(t, dir, from, index), from, index);
      if (t < TIMELINE) {
        raf = requestAnimationFrame(tick);
      } else {
        animating.current = false;
        setView((v) => (v.run === run ? { ...v, out: null } : v));
      }
    });
    return () => cancelAnimationFrame(raf);
    // `run` identifies the swap; the other values belong to it.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [run]);

  // Auto-play only while it can be seen and nobody is using it.
  useEffect(() => {
    const root = rootRef.current;
    if (!root || typeof IntersectionObserver === "undefined") return;
    const io = new IntersectionObserver(([entry]) => {
      onScreen.current = Boolean(entry?.isIntersecting);
    }, { threshold: 0.35 });
    io.observe(root);
    return () => io.disconnect();
  }, []);
  const n = view.list.length;
  const autoplaying = autoPlayMs > 0 && !paused && !reduced && n > 1;
  useEffect(() => {
    if (!autoplaying) return;
    const id = window.setInterval(() => {
      if (document.hidden || !onScreen.current || hovered.current || focused.current) return;
      if (Date.now() < holdUntil.current || animating.current) return;
      step(1, false);
    }, autoPlayMs);
    return () => window.clearInterval(id);
  }, [autoplaying, autoPlayMs, step]);

  if (n === 0) return null;
  const dish = view.list[wrapIndex(index, n)]!;
  const start = stripStart(index, n, VISIBLE_THUMBS);

  const onKeyDown = (e: KeyboardEvent) => {
    if (e.key === "ArrowRight") {
      e.preventDefault();
      step(1);
    } else if (e.key === "ArrowLeft") {
      e.preventDefault();
      step(-1);
    }
  };
  const onPointerDown = (e: ReactPointerEvent) => {
    swipe.current = { x: e.clientX, y: e.clientY };
    swiped.current = false;
  };
  const onPointerUp = (e: ReactPointerEvent) => {
    const s = swipe.current;
    swipe.current = null;
    if (!s) return;
    const dx = e.clientX - s.x;
    if (Math.abs(dx) > 40 && Math.abs(dx) > Math.abs(e.clientY - s.y) * 1.4) {
      swiped.current = true;
      step(dx < 0 ? 1 : -1);
    }
  };
  // A swipe over the plate must not also open the dish.
  const onClickCapture = (e: ReactMouseEvent) => {
    if (swiped.current) {
      e.preventDefault();
      e.stopPropagation();
      swiped.current = false;
    }
  };
  const toggle = (set: ReadonlySet<string>, key: string) => {
    const next = new Set(set);
    if (!next.delete(key)) next.add(key);
    return next;
  };
  const without = (set: ReadonlySet<string>, key: string) => {
    if (!set.has(key)) return set;
    const next = new Set(set);
    next.delete(key);
    return next;
  };
  const body = (role: Role, shown: Shown) => {
    const key = dishKey(shown.dish);
    return (
      <Body key={`${shown.position}:${key}`} role={role} dish={shown.dish} position={shown.position} ingredients={ingredients}
        liked={liked.has(key)} disliked={disliked.has(key)}
        onLike={() => { setLiked((s) => toggle(s, key)); setDisliked((s) => without(s, key)); }}
        onDislike={() => { setDisliked((s) => toggle(s, key)); setLiked((s) => without(s, key)); }} />
    );
  };
  const current: Shown = { dish, position: index };
  const keyOf = (s: Shown) => `${s.position}:${dishKey(s.dish)}`;

  return (
    <div className={cn("dsh-wrap", className)}>
      <div
        ref={rootRef}
        className="dsh-root"
        role="region"
        aria-roledescription="carousel"
        aria-label={label}
        tabIndex={0}
        onKeyDown={onKeyDown}
        onPointerEnter={(e) => { if (e.pointerType === "mouse") hovered.current = true; }}
        onPointerLeave={() => { hovered.current = false; }}
        onFocus={() => { focused.current = true; }}
        onBlur={(e) => { if (!e.currentTarget.contains(e.relatedTarget as Node | null)) focused.current = false; }}
      >
        <div className="dsh-canvas">
          <svg className="dsh-arc" viewBox="0 0 960 520" aria-hidden="true" focusable="false">
            <path ref={bandRef} className="dsh-band" />
          </svg>

          {autoPlayMs > 0 && !reduced && n > 1 && (
            <div className="dsh-top">
              <button type="button" className="dsh-btn" aria-label={paused ? "Play the dish slides" : "Pause the dish slides"} onClick={() => setPaused((p) => !p)}>
                {paused ? Icon.play : Icon.pause}
              </button>
            </div>
          )}

          <div className="dsh-stage">
            {n > 1 && (
              <div className="dsh-pager" role="group" aria-label="Choose a dish">
                {view.list.map((d, i) => (
                  <button key={`${i}:${dishKey(d)}`} type="button" className="dsh-btn dsh-dot" aria-current={i === index ? "true" : undefined}
                    aria-label={`Dish ${i + 1}: ${d.name}`} onClick={() => go(i)}>
                    <i />
                  </button>
                ))}
              </div>
            )}
            <div className="dsh-plates" onPointerDown={onPointerDown} onPointerUp={onPointerUp} onPointerCancel={() => { swipe.current = null; }}
              onClickCapture={onClickCapture}>
              {out && (
                <div key={keyOf(out)} className="dsh-orbit" data-role="out" data-part="plate" inert>
                  <PlateImage dish={out.dish} size={245} />
                </div>
              )}
              <div key={keyOf(current)} className="dsh-orbit" data-role="in" data-part="plate">
                <Link href={orderHref(dish)} className="dsh-link" tabIndex={-1} aria-hidden="true" draggable={false}>
                  <PlateImage dish={dish} size={245} />
                </Link>
              </div>
            </div>
          </div>

          <div className="dsh-head">
            {out && <Head key={keyOf(out)} role="out" dish={out.dish} position={out.position} />}
            <Head key={keyOf(current)} role="in" dish={dish} position={index} />
          </div>

          <div className="dsh-acts">
            {out && <Actions key={keyOf(out)} role="out" dish={out.dish} orderHref={orderHref} askHref={askHref} />}
            <Actions key={keyOf(current)} role="in" dish={dish} orderHref={orderHref} askHref={askHref} />
          </div>

          <div className="dsh-card">
            <div className="dsh-tabs" role="tablist" aria-label="Dish details">
              {([false, true] as const).map((tab) => (
                <button key={String(tab)} type="button" role="tab" className="dsh-btn dsh-tab" aria-selected={ingredients === tab}
                  aria-controls={panelId} onClick={() => setIngredients(tab)}>
                  {tab ? "Ingredients" : "Overview"}
                </button>
              ))}
            </div>
            <div className="dsh-bodies" id={panelId} role="tabpanel" aria-label={ingredients ? "Ingredients" : "Overview"}>
              {out && body("out", out)}
              {body("in", current)}
            </div>
          </div>

          {n > 1 && (
            <div className="dsh-strip">
              <button type="button" className="dsh-btn dsh-arrow" aria-label="Previous dish" onClick={() => step(-1)}>
                <svg viewBox="0 0 12 16" aria-hidden="true"><path d="M11 0v16L0 8z" /></svg>
              </button>
              <div className="dsh-win">
                <div className="dsh-track" style={{ transform: `translateX(${-start * THUMB}px)` }}>
                  {view.list.map((d, i) => (
                    <div key={`${i}:${dishKey(d)}`} className="dsh-th">
                      <button type="button" className="dsh-btn" aria-current={i === index ? "true" : undefined}
                        tabIndex={i >= start && i < start + VISIBLE_THUMBS ? 0 : -1} onClick={() => go(i)}>
                        <PlateImage dish={d} size={56} />
                        <span><span className="sr-only">Show</span> {d.name}</span>
                      </button>
                    </div>
                  ))}
                </div>
              </div>
              <button type="button" className="dsh-btn dsh-arrow" aria-label="Next dish" onClick={() => step(1)}>
                <svg viewBox="0 0 12 16" aria-hidden="true"><path d="M1 0v16l11-8z" /></svg>
              </button>
            </div>
          )}
        </div>
        <p className="sr-only" aria-live={autoplaying ? "off" : "polite"} aria-atomic="true">
          {`Dish ${index + 1} of ${n}: ${dish.name} from ${dish.restaurant_name}`}
        </p>
      </div>
    </div>
  );
}

export default DishOrbitCarousel;
