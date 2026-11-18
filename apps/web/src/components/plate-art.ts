/**
 * Illustrated plates for the Discover dish carousel: a dish seen from above, drawn in code (original art, no image
 * assets). A port of the mobile app's plate painter (mobile/customer/lib/ui/plates.dart) to SVG, so the website and
 * the app show the same dish families. The dish name picks the variant (jollof vs fried rice, egusi vs efo...) and
 * seeds the scatter, so every dish keeps the same plate between renders.
 */

/** Flutter-style colour: 0xAARRGGBB. */
type Argb = number;
type Pt = readonly [number, number];
interface Rect { x: number; y: number; w: number; h: number }
interface Shader { kind: "radial" | "linear"; coords: number[]; colors: Argb[]; stops?: number[] }
type Paint = { fill: Argb } | { stroke: Argb; width: number } | { shader: Shader };

const WHITE = 0xffffffff;
const BLACK = 0xff000000;
const BLACK87 = 0xdd000000;
const TAU = Math.PI * 2;

// ------------------------------------------------------------------------------------- colours and geometry
const channels = (c: Argb) => [(c >>> 24) & 255, (c >>> 16) & 255, (c >>> 8) & 255, c & 255] as const;

/** Color.lerp: every channel, alpha included. */
export function lerpColor(a: Argb, b: Argb, t: number): Argb {
  const ca = channels(a);
  const cb = channels(b);
  const [al, r, g, bl] = ca.map((v, i) => Math.round(v + (cb[i]! - v) * t));
  return ((al! << 24) | (r! << 16) | (g! << 8) | bl!) >>> 0;
}

const hex = (c: Argb) => "#" + (c & 0xffffff).toString(16).padStart(6, "0");
const alpha = (c: Argb) => ((c >>> 24) & 255) / 255;
const num = (v: number) => String(Math.round(v * 100) / 100);
const deg = (radians: number) => num((radians * 180) / Math.PI);

const fromCircle = ([cx, cy]: Pt, r: number): Rect => ({ x: cx - r, y: cy - r, w: 2 * r, h: 2 * r });
const fromCenter = ([cx, cy]: Pt, w: number, h: number): Rect => ({ x: cx - w / 2, y: cy - h / 2, w, h });
const ltwh = (x: number, y: number, w: number, h: number): Rect => ({ x, y, w, h });
const shiftRect = (r: Rect, dx: number, dy: number): Rect => ({ ...r, x: r.x + dx, y: r.y + dy });
const deflate = (r: Rect, d: number): Rect => ({ x: r.x + d, y: r.y + d, w: r.w - 2 * d, h: r.h - 2 * d });
const add = ([x, y]: Pt, dx: number, dy: number): Pt => [x + dx, y + dy];

/** Flutter RadialGradient over `rect`: centred at an alignment inside it, radius half the shortest side. */
function radial(rect: Rect, colors: Argb[], stops?: number[], center: Pt = [0, 0]): Paint {
  const cx = rect.x + rect.w / 2 + (center[0] * rect.w) / 2;
  const cy = rect.y + rect.h / 2 + (center[1] * rect.h) / 2;
  return { shader: { kind: "radial", coords: [cx, cy, Math.min(rect.w, rect.h) / 2], colors, stops } };
}

/** Flutter LinearGradient over `rect` between two alignments (default: centre left to centre right). */
function linear(rect: Rect, colors: Argb[], begin: Pt = [-1, 0], end: Pt = [1, 0]): Paint {
  const at = ([ax, ay]: Pt) => [rect.x + ((ax + 1) * rect.w) / 2, rect.y + ((ay + 1) * rect.h) / 2];
  return { shader: { kind: "linear", coords: [...at(begin), ...at(end)], colors } };
}

const fill = (c: Argb): Paint => ({ fill: c });
const line = (c: Argb, width: number): Paint => ({ stroke: c, width });

/** A path in Flutter's vocabulary; `shift` makes a moved copy (for drop shadows). */
class Path {
  private cmds: (string | number)[][] = [];
  moveTo(x: number, y: number) { this.cmds.push(["M", x, y]); return this; }
  lineTo(x: number, y: number) { this.cmds.push(["L", x, y]); return this; }
  quadTo(cx: number, cy: number, x: number, y: number) { this.cmds.push(["Q", cx, cy, x, y]); return this; }
  cubicTo(ax: number, ay: number, bx: number, by: number, x: number, y: number) { this.cmds.push(["C", ax, ay, bx, by, x, y]); return this; }
  close() { this.cmds.push(["Z"]); return this; }
  /** addArc: a new sub-path along the oval in `rect`, from `start` radians, sweeping `sweep` (clockwise positive). */
  arc(rect: Rect, start: number, sweep: number) {
    const rx = rect.w / 2;
    const ry = rect.h / 2;
    const cx = rect.x + rx;
    const cy = rect.y + ry;
    const end = start + sweep;
    this.cmds.push(["M", cx + rx * Math.cos(start), cy + ry * Math.sin(start)]);
    this.cmds.push(["A", rx, ry, 0, Math.abs(sweep) > Math.PI ? 1 : 0, sweep > 0 ? 1 : 0, cx + rx * Math.cos(end), cy + ry * Math.sin(end)]);
    return this;
  }
  shift(dx: number, dy: number): Path {
    const p = new Path();
    p.cmds = this.cmds.map(([op, ...v]) => {
      if (op === "A") return [op, v[0]!, v[1]!, v[2]!, v[3]!, v[4]!, (v[5] as number) + dx, (v[6] as number) + dy];
      return [op, ...v.map((n, i) => (n as number) + (i % 2 === 0 ? dx : dy))];
    });
    return p;
  }
  d(): string {
    return this.cmds.map(([op, ...v]) => op + v.map((n) => num(n as number)).join(" ")).join("");
  }
}

/** Collects SVG markup; gradients are de-duplicated into <defs>. */
class Canvas {
  private body: string[] = [];
  private gradientIds = new Map<string, string>();
  private defs: string[] = [];

  private paint(p: Paint): string {
    if ("fill" in p) {
      const a = alpha(p.fill);
      return `fill="${hex(p.fill)}"${a < 1 ? ` fill-opacity="${num(a)}"` : ""}`;
    }
    if ("stroke" in p) {
      const a = alpha(p.stroke);
      return `fill="none" stroke="${hex(p.stroke)}"${a < 1 ? ` stroke-opacity="${num(a)}"` : ""} stroke-width="${num(p.width)}" stroke-linecap="round"`;
    }
    const s = p.shader;
    const stops = s.colors.map((c, i) => {
      const at = s.stops?.[i] ?? (s.colors.length === 1 ? 0 : i / (s.colors.length - 1));
      const a = alpha(c);
      return `<stop offset="${num(at)}" stop-color="${hex(c)}"${a < 1 ? ` stop-opacity="${num(a)}"` : ""}/>`;
    }).join("");
    const [a, b, c, d] = s.coords.map(num);
    const attrs = s.kind === "radial" ? `cx="${a}" cy="${b}" r="${c}"` : `x1="${a}" y1="${b}" x2="${c}" y2="${d}"`;
    const key = s.kind + attrs + stops;
    let id = this.gradientIds.get(key);
    if (!id) {
      id = `g${this.gradientIds.size}`;
      this.gradientIds.set(key, id);
      const tag = s.kind === "radial" ? "radialGradient" : "linearGradient";
      this.defs.push(`<${tag} id="${id}" gradientUnits="userSpaceOnUse" ${attrs}>${stops}</${tag}>`);
    }
    return `fill="url(#${id})"`;
  }

  private push(tag: string, attrs: string, p: Paint, transform?: string) {
    this.body.push(`<${tag} ${attrs} ${this.paint(p)}${transform ? ` transform="${transform}"` : ""}/>`);
  }

  /** save / translate / rotate (radians) / scale ... restore. */
  group(transform: { at: Pt; rotate?: number; scale?: number }, draw: () => void) {
    const t = `translate(${num(transform.at[0])} ${num(transform.at[1])})` +
      (transform.rotate ? ` rotate(${deg(transform.rotate)})` : "") + (transform.scale ? ` scale(${num(transform.scale)})` : "");
    this.body.push(`<g transform="${t}">`);
    draw();
    this.body.push("</g>");
  }
  circle([cx, cy]: Pt, r: number, p: Paint) { this.push("circle", `cx="${num(cx)}" cy="${num(cy)}" r="${num(r)}"`, p); }
  oval(r: Rect, p: Paint) {
    this.push("ellipse", `cx="${num(r.x + r.w / 2)}" cy="${num(r.y + r.h / 2)}" rx="${num(r.w / 2)}" ry="${num(r.h / 2)}"`, p);
  }
  rect(r: Rect, p: Paint, radius = 0, transform?: string) {
    const rr = radius ? ` rx="${num(radius)}"` : "";
    this.push("rect", `x="${num(r.x)}" y="${num(r.y)}" width="${num(r.w)}" height="${num(r.h)}"${rr}`, p, transform);
  }
  line([x1, y1]: Pt, [x2, y2]: Pt, p: Paint) { this.push("line", `x1="${num(x1)}" y1="${num(y1)}" x2="${num(x2)}" y2="${num(y2)}"`, p); }
  path(path: Path, p: Paint) { this.push("path", `d="${path.d()}"`, p); }
  /** drawArc without the centre: an open arc along the oval in `rect`. */
  arc(r: Rect, start: number, sweep: number, p: Paint) { this.path(new Path().arc(r, start, sweep), p); }

  svg(): string {
    const defs = this.defs.length ? `<defs>${this.defs.join("")}</defs>` : "";
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">${defs}${this.body.join("")}</svg>`;
  }
}

/** Small, fast, seeded PRNG (mulberry32): the same dish always gets the same scatter. */
function seeded(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** The app's seed: name.toLowerCase().codeUnits.fold(7, (h, u) => (h * 31 + u) & 0x7fffffff). */
export function plateSeed(name: string): number {
  let h = 7;
  for (const ch of name.toLowerCase()) {
    for (let i = 0; i < ch.length; i++) h = (h * 31 + ch.charCodeAt(i)) & 0x7fffffff;
  }
  return h;
}

// ------------------------------------------------------------------------------------- drawing kit
class Draw {
  readonly c = new Canvas();
  private readonly n: string;
  private readonly rnd: () => number;

  constructor(name: string) {
    this.n = name.toLowerCase();
    this.rnd = seeded(plateSeed(name));
  }

  has(words: string[]) { return words.some((w) => this.n.includes(w)); }
  r(a: number, b: number) { return a + this.rnd() * (b - a); }
  int(k: number) { return Math.floor(this.rnd() * k); }
  pick<T>(list: readonly T[]): T { return list[this.int(list.length)]!; }

  // ------------------------------------------------------------------ dishes & bowls
  plate(rim: Argb = 0xfffbf8f3, well: Argb = 0xfff3ede4) {
    const o: Pt = [50, 50];
    this.c.circle(o, 49, radial(fromCircle(o, 49), [rim, lerpColor(rim, 0xffd9d0c3, 0.55)], [0.8, 1]));
    this.c.circle(o, 48.6, line(0x14000000, 0.8));
    this.c.circle(o, 38, radial(fromCircle(o, 38), [WHITE, well], [0.55, 1]));
    this.c.circle(o, 38, line(0x12000000, 0.9));
    // light catching the rim
    this.c.arc(fromCircle(o, 44), -2.6, 1.3, line(0x99ffffff, 2.4));
  }

  bowlBase(rim: Argb, inside: Argb, glaze?: Argb) {
    const o: Pt = [50, 50];
    this.c.circle(o, 49, radial(fromCircle(o, 49), [glaze ?? rim, lerpColor(rim, BLACK, 0.25)], [0.7, 1]));
    this.c.circle(o, 41, fill(lerpColor(rim, BLACK, 0.35)));
    this.c.circle(o, 39.5, radial(fromCircle(o, 39.5), [inside, lerpColor(inside, BLACK, 0.28)], [0.55, 1]));
    this.c.arc(fromCircle(o, 45), -2.7, 1.4, line(0x66ffffff, 2.2));
  }

  /** An irregular, hand-drawn looking blob. */
  blob([ox, oy]: Pt, radius: number, wobble = 0.12, points = 14): Path {
    const p = new Path();
    const rs = Array.from({ length: points }, () => radius * (1 + this.r(-wobble, wobble)));
    for (let i = 0; i <= points; i++) {
      const a = (i / points) * TAU;
      const rr = rs[i % points]!;
      const x = ox + Math.cos(a) * rr;
      const y = oy + Math.sin(a) * rr;
      if (i === 0) {
        p.moveTo(x, y);
      } else {
        const pa = ((i - 0.5) / points) * TAU;
        const pr = ((rs[(i - 1) % points]! + rr) / 2) * 1.04;
        p.quadTo(ox + Math.cos(pa) * pr, oy + Math.sin(pa) * pr, x, y);
      }
    }
    return p.close();
  }

  mound(o: Pt, radius: number, base: Argb, wobble = 0.1) {
    const path = this.blob(o, radius, wobble);
    this.c.path(path.shift(0, 1.6), fill(0x22000000));
    this.c.path(path, radial(fromCircle(o, radius), [lerpColor(base, WHITE, 0.18), base, lerpColor(base, BLACK, 0.18)], [0, 0.6, 1], [-0.3, -0.35]));
  }

  /** Rice-like grains scattered over a disc. */
  grains([ox, oy]: Pt, radius: number, colors: Argb[], count = 130, w = 2.6, h = 1.15) {
    for (let i = 0; i < count; i++) {
      const a = this.r(0, TAU);
      const d = Math.sqrt(this.rnd()) * radius;
      const turn = this.r(0, Math.PI);
      const color = this.pick(colors);
      this.c.rect(fromCenter([0, 0], w, h), fill(color), h / 2, `translate(${num(ox + Math.cos(a) * d)} ${num(oy + Math.sin(a) * d)}) rotate(${deg(turn)})`);
    }
  }

  dots([ox, oy]: Pt, spread: number, count: number, colors: Argb[], size = 1) {
    for (let i = 0; i < count; i++) {
      const a = this.r(0, TAU);
      const d = Math.sqrt(this.rnd()) * spread;
      const radius = size * this.r(0.7, 1.3);
      this.c.circle([ox + Math.cos(a) * d, oy + Math.sin(a) * d], radius, fill(this.pick(colors)));
    }
  }

  chunk(o: Pt, w: number, h: number, angle: number, color: Argb, radius = 2.2) {
    this.c.group({ at: o, rotate: angle }, () => {
      const rect = fromCenter([0, 0], w, h);
      this.c.rect(shiftRect(rect, 0.5, 1), fill(0x2a000000), radius);
      this.c.rect(rect, linear(rect, [lerpColor(color, WHITE, 0.22), color, lerpColor(color, BLACK, 0.25)], [-1, -1], [1, 1]), radius);
    });
  }

  leaf(o: Pt, length: number, angle: number, color: Argb) {
    this.c.group({ at: o, rotate: angle }, () => {
      const p = new Path().moveTo(-length / 2, 0).quadTo(0, -length * 0.38, length / 2, 0).quadTo(0, length * 0.38, -length / 2, 0).close();
      this.c.path(p, fill(color));
      this.c.line([-length / 2, 0], [length / 2.2, 0], line(lerpColor(color, WHITE, 0.35), 0.5));
    });
  }

  /** A round slice: tomato, cucumber, dodo, garden egg... */
  slice(o: Pt, radius: number, skin: Argb, flesh: Argb, seeds?: Argb, squash = 1) {
    const rect = fromCenter(o, radius * 2, radius * 2 * squash);
    this.c.oval(shiftRect(rect, 0.4, 0.9), fill(0x26000000));
    this.c.oval(rect, fill(skin));
    this.c.oval(deflate(rect, radius * 0.18), fill(flesh));
    if (seeds !== undefined) {
      for (let i = 0; i < 6; i++) {
        const a = (i / 6) * TAU;
        this.c.circle(add(o, Math.cos(a) * radius * 0.45, Math.sin(a) * radius * 0.45 * squash), radius * 0.12, fill(seeds));
      }
    }
  }

  ring(o: Pt, radius: number, color: Argb, width = 1.3) { this.c.circle(o, radius, line(color, width)); }

  tomatoes(o: Pt, count: number, size: number) {
    for (let i = 0; i < count; i++) {
      const at = add(o, this.r(-6, 6), this.r(-5, 5));
      this.slice(at, size * this.r(0.85, 1.1), 0xffd32f2f, 0xffef5350, 0xffffcdd2);
    }
  }

  onions(o: Pt, count: number, size: number) {
    for (let i = 0; i < count; i++) {
      const p = add(o, this.r(-7, 7), this.r(-6, 6));
      this.ring(p, size * this.r(0.8, 1.2), 0xff9c5ba9);
      this.ring(p, size * this.r(0.45, 0.6), 0xcce1bee7, 0.9);
    }
  }

  dodo([ox, oy]: Pt, count: number) {
    for (let i = 0; i < count; i++) {
      const at: Pt = [ox + this.r(-6, 6), oy + this.r(-5, 5)];
      this.c.group({ at, rotate: this.r(-1, 1) }, () => {
        const rect = fromCenter([0, 0], this.r(10, 12.5), this.r(6.5, 8));
        this.c.oval(shiftRect(rect, 0.5, 1), fill(0x30000000));
        this.c.oval(rect, radial(rect, [0xfff8c15c, 0xffe69a2e, 0xffb8641a], [0, 0.65, 1]));
      });
    }
  }

  drumstick(o: Pt, angle: number, scale = 1) {
    this.c.group({ at: o, rotate: angle, scale: scale === 1 ? undefined : scale }, () => {
      const meat = new Path().moveTo(-13, 0).cubicTo(-13, -10, 3, -9, 6, -3).lineTo(12, -1.6).lineTo(12, 1.6).lineTo(6, 3)
        .cubicTo(3, 9, -13, 10, -13, 0).close();
      this.c.path(meat.shift(0.8, 1.4), fill(0x33000000));
      this.c.path(meat, radial(ltwh(-13, -10, 25, 20), [0xffd4843f, 0xffa2491a, 0xff6b2b0c], [0, 0.6, 1], [-0.3, -0.4]));
      for (let i = 0; i < 3; i++) this.c.line([-9 + i * 5, -6], [-6 + i * 5, 6], line(0x553b1406, 1.4));
      this.c.rect(ltwh(11, -1.4, 6, 2.8), fill(0xfff6ead8), 1.4);
      this.c.circle([17.5, -1.8], 2.3, fill(0xfff6ead8));
      this.c.circle([17.5, 1.8], 2.3, fill(0xfff6ead8));
    });
  }

  greens(o: Pt, count: number, size = 7) {
    const shades = [0xff2e7d32, 0xff43a047, 0xff66bb6a, 0xff1b5e20];
    for (let i = 0; i < count; i++) {
      const at = add(o, this.r(-8, 8), this.r(-7, 7));
      const length = size * this.r(0.8, 1.3);
      const angle = this.r(0, Math.PI);
      this.leaf(at, length, angle, this.pick(shades));
    }
  }

  // ------------------------------------------------------------------ families
  rice() {
    this.plate();
    const [base, light, dark] = this.has(["fried"])
      ? [0xffe2b84c, 0xfff4d98a, 0xffc0912c]
      : this.has(["ofada"])
        ? [0xffcdb892, 0xffe6d8b9, 0xffae9567]
        : this.has(["coconut"])
          ? [0xffefe3c6, 0xfffff6e3, 0xffd8c7a1]
          : [0xffd9572a, 0xfff07a3e, 0xffb8421b];
    const o: Pt = [44, 50];
    this.mound(o, 26, base);
    this.grains(o, 24, [light, base, dark, light], 170);
    if (this.has(["fried"])) {
      this.dots(o, 22, 18, [0xff5fa83a, 0xff7cc24e], 1.4);
      for (let i = 0; i < 12; i++) this.chunk(add(o, this.r(-18, 18), this.r(-16, 16)), 2.4, 2.4, this.r(0, 1), 0xfff08a2b, 0.5);
    }
    if (this.has(["ofada"])) {
      // ayamase: green pepper stew with red oil and assorted meat
      this.c.path(this.blob([66, 60], 15, 0.16), fill(0xff3e5a23));
      this.dots([66, 60], 12, 20, [0xccb71c1c, 0x99e65100], 1.3);
      for (let i = 0; i < 4; i++) this.chunk([this.r(58, 74), this.r(52, 68)], 6, 4.5, this.r(0, 3), 0xff6d3b22);
    } else {
      this.drumstick([66, 40], -0.6);
      this.dodo([66, 66], 3);
    }
    this.greens([32, 70], 2, 6);
    this.tomatoes([30, 32], 1, 4.5);
  }

  soupAndSwallow() {
    this.plate();
    // soup bowl on the plate
    const soupAt: Pt = [37, 45];
    this.c.circle(add(soupAt, 0, 1.6), 23, fill(0x26000000));
    this.c.circle(soupAt, 23, fill(WHITE));
    this.c.circle(soupAt, 23, line(0x14000000, 0.8));
    const [soup, specks]: [Argb, Argb[]] = this.has(["gbegiri"])
      ? [0xffe2a93b, [0xfff2c866, 0xffc88a23]]
      : this.has(["efo", "edikang", "afang"])
        ? [0xff2e5e2a, [0xff3e7d35, 0xff1e431c, 0xccb71c1c]]
        : this.has(["onugbu", "bitterleaf", "oha", "owerri"])
          ? [0xff4b4a22, [0xff6b6b2e, 0xff2f3a17, 0xaac0392b]]
          : this.has(["okra", "ogbono"])
            ? [0xff6b8a33, [0xff8daa4a, 0xffe8e2b0]]
            : this.has(["banga"])
              ? [0xffb45a24, [0xffd9823c, 0xff7a3712]]
              : [0xffb8a23e, [0xffe6d58a, 0xff8c7a24, 0xaad84315]]; // egusi
    this.c.circle(soupAt, 19.5, radial(fromCircle(soupAt, 19.5), [lerpColor(soup, WHITE, 0.12), soup, lerpColor(soup, BLACK, 0.22)], [0, 0.7, 1]));
    if (this.has(["gbegiri"]) && this.has(["ewedu"])) {
      // gbegiri and ewedu side by side
      this.c.path(new Path().arc(fromCircle(soupAt, 19.5), 0.9, 2.4), fill(0xff4c7f2e));
      this.dots(add(soupAt, -6, 8), 7, 16, [0xff6fa64a, 0xff2f5a1c], 0.9);
    }
    this.dots(soupAt, 16, 46, specks, 1.2);
    for (let i = 0; i < 4; i++) {
      const at = add(soupAt, this.r(-11, 11), this.r(-11, 11));
      this.chunk(at, this.r(5, 7), this.r(4, 5.5), this.r(0, 3), 0xff6d3b22);
    }
    // a slick of palm oil
    this.c.oval(fromCenter(add(soupAt, 6, -7), 9, 4), fill(0x55ff8f00));

    // the swallow, wrapped and glossy
    const swallow = this.has(["amala"]) ? 0xff6b4e3d
      : this.has(["eba", "garri"]) ? 0xffe9d79e
        : this.has(["semo", "semovita", "fufu"]) ? 0xfff1e9d8
          : 0xfff5f0e6; // pounded yam
    const ballAt: Pt = [69, 64];
    this.c.circle(add(ballAt, 0.8, 2), 17, fill(0x33000000));
    this.c.circle(ballAt, 17, radial(fromCircle(ballAt, 17), [lerpColor(swallow, WHITE, 0.35), swallow, lerpColor(swallow, BLACK, 0.2)], [0, 0.55, 1], [-0.35, -0.4]));
    this.c.arc(fromCircle(ballAt, 12), -2.5, 1.1, line(0x88ffffff, 2));
    this.greens([72, 36], 1, 6);
  }

  broth() {
    this.bowlBase(0xff9c4a26, 0xff8e3a16, 0xffb65a2e);
    const o: Pt = [50, 50];
    // pepper soup: catfish or goat pieces in a deep red-brown broth
    const fish = this.has(["fish", "catfish", "point and kill"]);
    for (let i = 0; i < 5; i++) {
      const p = add(o, this.r(-18, 18), this.r(-18, 18));
      if (fish) {
        this.c.circle(add(p, 0.5, 1), 6.2, fill(0x33000000));
        this.c.circle(p, 6.2, fill(0xff6e5a4c));
        this.c.circle(p, 4.4, fill(0xffe2cfb6));
        this.c.circle(p, 1.2, fill(0xffbfa88a));
      } else {
        this.chunk(p, this.r(7, 9), this.r(5, 7), this.r(0, 3), 0xff6d3b22);
      }
    }
    this.dots(o, 30, 30, [0x66ffb74d, 0x44ffe0b2], 1.8); // oil sheen
    this.dots(o, 30, 26, [0xffe53935, 0xffff7043], 0.7); // pepper
    this.greens([46, 40], 3, 6.5); // scent leaf
  }

  skewers() {
    this.plate();
    if (this.has(["asun", "gizzard"])) {
      for (let i = 0; i < 16; i++) {
        const at: Pt = [this.r(28, 72), this.r(28, 72)];
        this.chunk(at, this.r(6, 8.5), this.r(5, 7), this.r(0, 3), 0xff7b2e12);
      }
      this.dots([50, 50], 24, 30, [0xffd32f2f, 0xff43a047, 0xffffb300], 1.4);
    } else {
      for (let k = 0; k < 3; k++) {
        const y = 36 + k * 13;
        const from: Pt = [20, y + 10];
        const to: Pt = [80, y - 10];
        this.c.line(from, to, line(0xffc9a06a, 1.6));
        for (let i = 0; i < 5; i++) {
          const t = 0.14 + i * 0.17;
          const p: Pt = [from[0] + (to[0] - from[0]) * t, from[1] + (to[1] - from[1]) * t];
          this.chunk(p, 9, 7, -0.32 + this.r(-0.15, 0.15), i % 2 === 0 ? 0xff7b2e12 : 0xff8e3a16);
        }
      }
      // yaji spice
      this.dots([50, 48], 28, 60, [0xffd9893b, 0xff5a2a12, 0xffb0532a], 0.7);
    }
    this.onions([30, 72], 2, 5);
    this.tomatoes([70, 74], 2, 4.6);
    // cabbage shreds
    for (let i = 0; i < 8; i++) {
      const p: Pt = [this.r(40, 60), this.r(70, 80)];
      const rect = fromCenter(p, this.r(6, 9), this.r(3, 5));
      this.c.arc(rect, this.r(0, 3), 2.2, line(0xffc5e1a5, 1.1));
    }
  }

  grill() {
    this.plate();
    if (this.has(["croaker", "fish", "tilapia"])) {
      // a whole grilled fish with grill marks
      this.c.group({ at: [48, 48], rotate: -0.5 }, () => {
        const body = new Path().moveTo(-30, 0).cubicTo(-22, -13, 14, -14, 22, -2).lineTo(32, -9).lineTo(30, 0).lineTo(32, 9).lineTo(22, 2)
          .cubicTo(14, 14, -22, 13, -30, 0).close();
        this.c.path(body.shift(1, 2), fill(0x33000000));
        this.c.path(body, linear(ltwh(-30, -14, 62, 28), [0xffb07a4a, 0xff8a5530, 0xff5e3a20], [0, -1], [0, 1]));
        for (let i = 0; i < 6; i++) this.c.line([-18 + i * 6, -9], [-22 + i * 6, 9], line(0x993b2210, 1.5));
        this.c.circle([-22, -3], 2.2, fill(WHITE));
        this.c.circle([-22, -3], 1.1, fill(BLACK87));
      });
      if (this.has(["bole"])) {
        for (let i = 0; i < 3; i++) {
          this.chunk([this.r(64, 78), this.r(66, 78)], 12, 6, this.r(-0.6, 0.6), 0xffd99a3b);
          const a: Pt = [this.r(64, 76), this.r(66, 76)];
          const b: Pt = [this.r(66, 78), this.r(68, 78)];
          this.c.line(a, b, line(0xaa3e2723, 1.2));
        }
      }
    } else {
      // grilled chicken quarter with peppers
      const o: Pt = [46, 48];
      const p = this.blob(o, 21, 0.16, 10);
      this.c.path(p.shift(1, 2), fill(0x33000000));
      this.c.path(p, radial(fromCircle(o, 21), [0xffe09a4e, 0xffb8641e, 0xff7a3510], [0, 0.6, 1], [-0.3, -0.4]));
      for (let i = 0; i < 5; i++) this.c.line([30 + i * 7, 32], [26 + i * 7, 64], line(0x88401708, 1.8));
      this.drumstick([70, 34], 0.9, 0.7);
    }
    // peppers & onion
    for (let i = 0; i < 4; i++) {
      const at: Pt = [this.r(60, 78), this.r(56, 74)];
      this.chunk(at, 7, 3, this.r(0, 3), i % 2 === 0 ? 0xffd32f2f : 0xff43a047, 1.5);
    }
    this.onions([30, 74], 2, 4.5);
  }

  pizza() {
    // wooden board
    const o: Pt = [50, 50];
    this.c.circle(o, 49, radial(fromCircle(o, 49), [0xffc9955a, 0xff9c6b37], [0.75, 1]));
    this.c.circle(add(o, 0.8, 1.6), 43, fill(0x33000000));
    this.c.circle(o, 43, radial(fromCircle(o, 43), [0xfff1c27a, 0xffd9963f], [0.82, 1]));
    this.c.circle(o, 36, fill(0xffc6402b));
    // cheese
    for (let i = 0; i < 14; i++) {
      const a = this.r(0, TAU);
      const d = Math.sqrt(this.rnd()) * 28;
      const radius = this.r(5, 8);
      this.c.path(this.blob(add(o, Math.cos(a) * d, Math.sin(a) * d), radius, 0.25, 8), fill(0xfff7d98f));
    }
    if (this.has(["margherita"])) {
      for (let i = 0; i < 6; i++) {
        const a = (i / 6) * TAU;
        this.c.circle(add(o, Math.cos(a) * 20, Math.sin(a) * 20), 5.5, fill(0xfffff4da));
      }
      this.greens(o, 5, 7);
    } else {
      const suya = this.has(["suya"]);
      for (let i = 0; i < 14; i++) {
        const a = this.r(0, TAU);
        const d = Math.sqrt(this.rnd()) * 30;
        this.chunk(add(o, Math.cos(a) * d, Math.sin(a) * d), 5, 4, this.r(0, 3), suya ? 0xff7b2e12 : 0xffb8641e, 1.5);
      }
      for (let i = 0; i < 8; i++) {
        const a = this.r(0, TAU);
        const d = Math.sqrt(this.rnd()) * 28;
        this.chunk(add(o, Math.cos(a) * d, Math.sin(a) * d), 6, 2.4, this.r(0, 3), i % 2 === 0 ? 0xff43a047 : 0xffffb300, 1);
      }
      this.onions(o, 3, 4.5);
    }
    // slice cuts
    for (let i = 0; i < 6; i++) {
      const a = (i / 6) * TAU + 0.3;
      this.c.line(o, add(o, Math.cos(a) * 42, Math.sin(a) * 42), line(0x55000000, 0.7));
    }
  }

  wrap() {
    this.plate();
    for (const [o, angle] of [[[42, 44], -0.55], [[58, 58], -0.55]] as [Pt, number][]) {
      this.c.group({ at: o, rotate: angle }, () => {
        const rect = ltwh(-24, -9, 48, 18);
        this.c.rect(shiftRect(rect, 1, 2), fill(0x33000000), 9);
        this.c.rect(rect, linear(rect, [0xfff0c989, 0xffd9a35b, 0xffb37a38], [0, -1], [0, 1]), 9);
        for (let i = 0; i < 5; i++) this.c.line([-16 + i * 8, -8], [-20 + i * 8, 8], line(0x66704214, 1.4));
        // wrapper paper with a stripe
        this.c.rect(ltwh(8, -9.6, 17, 19.2), fill(0xfffafafa), 4);
        this.c.rect(ltwh(14, -9.6, 3, 19.2), fill(0xffe0040b));
        // the cut end: chicken, cabbage, carrot, sauce
        const end: Pt = [-22, 0];
        this.c.circle(end, 8, fill(0xfff3e1be));
        this.dots(end, 6, 14, [0xffc7894b, 0xffcfe8a5, 0xfff08a2b, 0xffffffff, 0xffd32f2f], 1.3);
      });
    }
  }

  bites() {
    this.plate();
    const puff = (p: Pt, radius: number) => {
      this.c.circle(add(p, 0.6, 1.4), radius, fill(0x33000000));
      this.c.circle(p, radius, radial(fromCircle(p, radius), [0xfff6c66a, 0xffdb8a2c, 0xff9c5214], [0, 0.6, 1], [-0.35, -0.4]));
    };
    if (this.has(["puff"])) {
      for (const p of [[36, 38], [54, 34], [66, 50], [46, 54], [30, 58], [58, 68], [42, 72]] as Pt[]) {
        const at = add(p, this.r(-2, 2), this.r(-2, 2));
        puff(at, this.r(8, 10));
      }
      this.dots([50, 52], 26, 40, [0xeeffffff], 0.6); // sugar
      return;
    }
    if (this.has(["fries", "chips"])) {
      for (let i = 0; i < 26; i++) {
        const at: Pt = [this.r(28, 72), this.r(28, 72)];
        this.chunk(at, this.r(14, 20), 3.6, this.r(0, 3), 0xfff2c14e, 1.2);
      }
      if (this.has(["loaded"])) this.dots([50, 50], 18, 30, [0xfffff59d, 0xffd32f2f, 0xff7b2e12], 1.6);
      return;
    }
    if (this.has(["meat pie", "pie"])) {
      for (const [p, a] of [[[38, 42], -0.4], [[62, 46], 0.5], [[48, 66], 0.1]] as [Pt, number][]) {
        this.c.group({ at: p, rotate: a }, () => {
          const pie = new Path().arc(ltwh(-15, -15, 30, 30), Math.PI, Math.PI).close();
          this.c.path(pie.shift(0.6, 1.6), fill(0x33000000));
          this.c.path(pie, linear(ltwh(-15, -15, 30, 15), [0xfff2cb7e, 0xffd99a45]));
          for (let i = 0; i < 9; i++) this.c.circle([-13 + i * 3.25, 0], 1, fill(0xffb8782e));
        });
      }
      return;
    }
    if (this.has(["moi moi", "moimoi"])) {
      this.leaf([50, 50], 70, -0.5, 0xff3e7d35);
      this.c.path(this.blob([50, 50], 18, 0.08), fill(0xffe07a3f));
      this.dots([50, 50], 14, 14, [0xfff5e6c8, 0xff7b2e12], 1.4);
      return;
    }
    // small chops platter: puff-puff, spring rolls, samosa and peppered gizzard
    for (const p of [[34, 36], [44, 30], [30, 48]] as Pt[]) puff(p, 7.5);
    for (let i = 0; i < 3; i++) this.chunk([62 + i * 4, 34 + i * 7], 22, 6.5, -0.5, 0xffd9a35b, 3);
    for (const [p, a] of [[[38, 66], 0.2], [[54, 70], -0.3]] as [Pt, number][]) {
      this.c.group({ at: p, rotate: a }, () => {
        const tri = new Path().moveTo(0, -9).lineTo(9, 7).lineTo(-9, 7).close();
        this.c.path(tri.shift(0.6, 1.4), fill(0x33000000));
        this.c.path(tri, fill(0xffd99a45));
      });
    }
    for (let i = 0; i < 5; i++) {
      const at: Pt = [this.r(64, 76), this.r(58, 72)];
      this.chunk(at, 5, 4, this.r(0, 3), 0xff6d2a12);
    }
  }

  bowl() {
    const o: Pt = [50, 50];
    const far = (p: Pt, limit: number) => Math.hypot(p[0] - o[0], p[1] - o[1]) > limit;
    if (this.has(["parfait", "yoghurt", "yogurt", "granola"])) {
      this.bowlBase(0xffe8f1f7, WHITE, 0xfff7fbfe); // a glass
      this.c.circle(o, 36, fill(0xfffffbf2));
      this.dots(o, 30, 26, [0xffb07a3a, 0xffd9a35b, 0xff8d5a2b], 2.2); // granola
      for (let i = 0; i < 7; i++) {
        const p = add(o, this.r(-24, 24), this.r(-24, 24));
        this.c.circle(p, this.r(3, 4), fill(i % 2 === 0 ? 0xffc62828 : 0xff5e35b1));
      }
      for (let i = 0; i < 6; i++) {
        const at = add(o, this.r(-20, 20), this.r(-20, 20));
        this.chunk(at, 5, 5, this.r(0, 1), 0xffffb300, 1);
      }
      this.greens(add(o, 4, -6), 1, 6);
      return;
    }
    if (this.has(["fruit"])) {
      this.bowlBase(0xfff4efe6, WHITE);
      const colors = [0xffe53935, 0xffffc107, 0xffff8f00, 0xff7cb342, 0xff8e24aa];
      for (let i = 0; i < 26; i++) {
        const p = add(o, this.r(-28, 28), this.r(-28, 28));
        if (far(p, 32)) continue;
        const w = this.r(5, 7);
        const h = this.r(5, 7);
        const angle = this.r(0, 2);
        this.chunk(p, w, h, angle, this.pick(colors), 1.4);
      }
      return;
    }
    this.bowlBase(0xfff4efe6, WHITE);
    if (this.has(["abacha"])) {
      // shredded cassava with ugba, palm-oil dressing, fish and garden egg
      this.c.circle(o, 34, fill(0x66e65100));
      for (let i = 0; i < 60; i++) {
        const p = add(o, this.r(-26, 26), this.r(-26, 26));
        if (far(p, 30)) continue;
        const rect = fromCenter(p, this.r(6, 10), this.r(2, 4));
        this.c.arc(rect, this.r(0, 3), 2.4, line(0xfff1e3c8, 1.3));
      }
      this.dots(o, 26, 24, [0xff4e342e, 0xff6d4c41], 1.6);
      for (let i = 0; i < 3; i++) this.slice(add(o, this.r(-16, 16), this.r(-16, 16)), 5, 0xffdce775, 0xfffafaf0, 0xffbdb76b);
      this.chunk(add(o, 12, 10), 14, 9, 0.4, 0xff8d6e63);
      this.onions(add(o, -10, 8), 2, 4.5);
      this.greens(add(o, -6, -14), 2, 6);
      return;
    }
    // salad or power bowl: greens with toppings in sections
    this.greens(add(o, -10, -8), 14, 9);
    if (this.has(["plantain", "bean"])) {
      this.dots(add(o, 10, -10), 10, 40, [0xff8d5524, 0xff6d3b1f], 1.9); // beans
      for (let i = 0; i < 7; i++) this.chunk(add(o, this.r(4, 20), this.r(4, 20)), 5, 5, this.r(0, 1), 0xfff2a93b, 1.2); // plantain
    }
    if (this.has(["quinoa"])) {
      this.dots(add(o, 8, 8), 14, 90, this.has(["jollof"]) ? [0xffe8763a, 0xfff29a5b] : [0xffe6d3a3, 0xffd1bc8a], 0.9);
    }
    if (this.has(["chicken"])) {
      for (let i = 0; i < 5; i++) this.chunk(add(o, 4 + i * 3, 6 + i * 2.5), 12, 4.5, -0.6, 0xffc98a4b, 2);
    }
    // avocado and egg
    for (let i = 0; i < 3; i++) {
      this.c.group({ at: [o[0] - 16 + i * 4, o[1] + 14], rotate: -0.4 }, () => {
        this.c.oval(ltwh(-6, -3, 12, 6), fill(0xff9ccc65));
        this.c.oval(ltwh(-6, -3, 12, 2.4), fill(0xff33691e));
      });
    }
    this.slice(add(o, 16, -16), 6, WHITE, 0xffffc107);
    this.tomatoes(add(o, -14, -16), 2, 3.6);
  }

  generic() {
    this.plate();
    const o: Pt = [48, 50];
    this.mound(o, 22, 0xffe8a23b);
    this.grains(o, 20, [0xfff7c46a, 0xffd4882a], 90);
    this.greens([66, 38], 2, 7);
    this.tomatoes([66, 64], 2, 4.5);
  }
}

/** The dish families the API sends in `art`. Anything else gets the generic plate. */
export const PLATE_FAMILIES = ["rice", "soup_swallow", "broth", "skewers", "grill", "pizza", "wrap", "bites", "bowl", "plate"] as const;

/** The plate as SVG markup, 100 × 100. Deterministic for a given dish. */
export function plateSvg(art: string, name: string): string {
  const d = new Draw(name);
  switch (art) {
    case "rice": d.rice(); break;
    case "soup_swallow": d.soupAndSwallow(); break;
    case "broth": d.broth(); break;
    case "skewers": d.skewers(); break;
    case "grill": d.grill(); break;
    case "pizza": d.pizza(); break;
    case "wrap": d.wrap(); break;
    case "bites": d.bites(); break;
    case "bowl": d.bowl(); break;
    default: d.generic();
  }
  return d.c.svg();
}

const cache = new Map<string, string>();

/** The plate as an image URL (data: URI), cached per dish. */
export function plateImage(art: string, name: string): string {
  const key = art + "\u0000" + name;
  let url = cache.get(key);
  if (!url) {
    url = "data:image/svg+xml;charset=utf-8," + encodeURIComponent(plateSvg(art, name));
    if (cache.size > 200) cache.clear();
    cache.set(key, url);
  }
  return url;
}
