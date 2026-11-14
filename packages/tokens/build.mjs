// Generates platform outputs from tokens.json (the Dart file is deliberately not named *.g.dart):
//   packages/tokens/tokens.css           — CSS custom properties (light, dark, data-theme overrides)
//   packages/tokens/tokens.ts            — typed constants for TS consumers
//   mobile/core/lib/src/theme/gm_tokens.dart — Flutter colours/radii
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const tokens = JSON.parse(readFileSync(resolve(here, "tokens.json"), "utf8"));
const header = "Generated from packages/tokens/tokens.json by build.mjs — do not edit by hand.";

const vars = (palette) =>
  Object.entries(palette).map(([k, v]) => `  --gm-${k}: ${v};`).join("\n");
const radii = Object.entries(tokens.radius).map(([k, v]) => `  --gm-radius-${k}: ${v}px;`).join("\n");

const css = `/* ${header} */
:root {
${vars(tokens.color.light)}
${radii}
  --gm-shadow-card: ${tokens.elevation.card};
  --gm-shadow-raised: ${tokens.elevation.raised};
  color-scheme: light;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
${vars(tokens.color.dark).replaceAll("  --", "    --")}
    color-scheme: dark;
  }
}
:root[data-theme="dark"] {
${vars(tokens.color.dark)}
  color-scheme: dark;
}
`;
writeFileSync(resolve(here, "tokens.css"), css);

const ts = `// ${header}
export const tokens = ${JSON.stringify(tokens, null, 2)} as const;
export type ColorToken = keyof typeof tokens.color.light;
`;
writeFileSync(resolve(here, "tokens.ts"), ts);

const dartColor = (hex) => `Color(0xFF${hex.replace("#", "").toUpperCase()})`;
const camel = (k) => k.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
const dartPalette = (name, palette) =>
  `class ${name} {\n  const ${name}._();\n` +
  Object.entries(palette).map(([k, v]) => `  static const ${camel(k)} = ${dartColor(v)};`).join("\n") + "\n}\n";
const dart = `// ${header}
// ignore_for_file: constant_identifier_names
import 'package:flutter/painting.dart';

${dartPalette("GmLight", tokens.color.light)}
${dartPalette("GmDark", tokens.color.dark)}
class GmRadius {
  const GmRadius._();
${Object.entries(tokens.radius).map(([k, v]) => `  static const double ${camel(k)} = ${v};`).join("\n")}
}

class GmFonts {
  const GmFonts._();
  static const display = '${tokens.font.display}';
  static const body = '${tokens.font.body}';
}
`;
const dartOut = resolve(here, "../../mobile/core/lib/src/theme/gm_tokens.dart");
mkdirSync(dirname(dartOut), { recursive: true });
writeFileSync(dartOut, dart);
console.log("tokens: wrote tokens.css, tokens.ts and gm_tokens.dart");
