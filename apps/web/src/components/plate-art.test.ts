import { describe, expect, it } from "vitest";
import { lerpColor, PLATE_FAMILIES, plateImage, plateSeed, plateSvg } from "./plate-art";

const parse = (svg: string) => new DOMParser().parseFromString(svg, "image/svg+xml");

describe("illustrated plates", () => {
  it("draws every dish family the API sends as well-formed SVG", () => {
    const names: Record<string, string[]> = {
      rice: ["Party Jollof Rice", "Chicken Fried Rice", "Ofada Rice & Ayamase", "Coconut Rice"],
      soup_swallow: ["Amala, Gbegiri & Ewedu", "Edikang Ikong & Swallow", "Egusi & Pounded Yam", "Okra Soup & Eba"],
      broth: ["Catfish Pepper Soup", "Goat Meat Pepper Soup"],
      skewers: ["Beef Suya (250g)", "Asun"],
      grill: ["Whole Grilled Croaker (serves 2)", "Bole & Fish", "Grilled Chicken"],
      pizza: ["Suya pizza (medium)", "Margherita"],
      wrap: ["Chicken Shawarma"],
      bites: ["Small Chops Platter (serves 2)", "Puff-puff", "Loaded Fries", "Meat Pie", "Moi Moi"],
      bowl: ["Yoghurt & granola parfait", "Fruit salad bowl", "Abacha", "Plantain & Bean Power Bowl", "Jollof Quinoa Chicken Bowl"],
      plate: ["Something new"],
    };
    for (const art of [...PLATE_FAMILIES, "unknown"]) {
      for (const name of names[art] ?? ["Chef's special"]) {
        const svg = plateSvg(art, name);
        const doc = parse(svg);
        expect(doc.getElementsByTagName("parsererror"), `${art}: ${name}`).toHaveLength(0);
        expect(doc.documentElement.getAttribute("viewBox")).toBe("0 0 100 100");
        expect(doc.documentElement.childElementCount).toBeGreaterThan(5);
        for (const use of doc.querySelectorAll("[fill^='url(#']")) {
          const id = use.getAttribute("fill")!.slice(5, -1);
          expect(doc.getElementById(id), `${art}: ${name} gradient ${id}`).not.toBeNull();
        }
      }
    }
  });

  it("keeps each dish's plate stable and tells the variants apart", () => {
    expect(plateSvg("rice", "Party Jollof Rice")).toBe(plateSvg("rice", "Party Jollof Rice"));
    expect(plateSvg("rice", "Party Jollof Rice")).toContain("#d9572a"); // jollof red
    expect(plateSvg("rice", "Chicken Fried Rice")).toContain("#e2b84c"); // fried-rice gold
    const amala = plateSvg("soup_swallow", "Amala, Gbegiri & Ewedu");
    expect(amala).toContain("#4c7f2e"); // ewedu beside the gbegiri
    expect(amala).toContain("#6b4e3d"); // amala
    expect(plateSvg("pizza", "Margherita")).not.toBe(plateSvg("pizza", "Suya pizza (medium)"));
  });

  it("seeds the scatter from the name exactly like the app, and serves cached data URLs", () => {
    expect(plateSeed("Suya")).toBe(10_006_897);
    expect(plateSeed("SUYA")).toBe(plateSeed("suya"));
    expect(lerpColor(0xff000000, 0xffffffff, 0.5)).toBe(0xff808080);
    const url = plateImage("wrap", "Chicken Shawarma");
    expect(url.startsWith("data:image/svg+xml;charset=utf-8,")).toBe(true);
    expect(plateImage("wrap", "Chicken Shawarma")).toBe(url);
    expect(decodeURIComponent(url.split(",").slice(1).join(","))).toBe(plateSvg("wrap", "Chicken Shawarma"));
  });
});
