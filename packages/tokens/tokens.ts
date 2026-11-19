// Generated from packages/tokens/tokens.json by build.mjs — do not edit by hand.
export const tokens = {
  "$description": "Yummy Chops design tokens — the single source for web (CSS variables / Tailwind) and Flutter (Dart). Colours come from the Yummy Chops logo (assets/brand/yummychops-logo.webp): the red of \"Meals\", the chocolate brown of \"Gud\", the orange-gold of the arc and the green of the leaf (ADR-0022).",
  "color": {
    "light": {
      "primary": "#E0040B",
      "primary-strong": "#B3050B",
      "primary-soft": "#FDE7E6",
      "on-primary": "#FFFFFF",
      "secondary": "#3A0D05",
      "secondary-soft": "#F4E8E3",
      "on-secondary": "#FFFFFF",
      "accent": "#F5A21A",
      "accent-soft": "#FEF1DA",
      "background": "#FFFBF8",
      "surface": "#FFFFFF",
      "surface-muted": "#F8EFEA",
      "border": "#EFE0D8",
      "text": "#2A0D06",
      "muted": "#7A625A",
      "success": "#2E8B1E",
      "warning": "#B35A06",
      "danger": "#C0161C",
      "info": "#1E63B6"
    },
    "dark": {
      "primary": "#FF5A4F",
      "primary-strong": "#FF8077",
      "primary-soft": "#3D1512",
      "on-primary": "#1F0503",
      "secondary": "#E7B48F",
      "secondary-soft": "#3A2218",
      "on-secondary": "#1F0D06",
      "accent": "#FFB43D",
      "accent-soft": "#3E2B10",
      "background": "#160C08",
      "surface": "#21130D",
      "surface-muted": "#2B1A13",
      "border": "#3E2A21",
      "text": "#FBF0EA",
      "muted": "#C5ACA1",
      "success": "#5DBB46",
      "warning": "#F2A65A",
      "danger": "#FF6B61",
      "info": "#6BA8E0"
    }
  },
  "radius": {
    "sm": 8,
    "md": 12,
    "lg": 16,
    "xl": 24,
    "pill": 999
  },
  "font": {
    "display": "Nunito",
    "body": "Plus Jakarta Sans"
  },
  "elevation": {
    "card": "0 1px 2px rgba(58,13,5,.06), 0 8px 24px rgba(58,13,5,.06)",
    "raised": "0 12px 32px rgba(58,13,5,.12)"
  }
} as const;
export type ColorToken = keyof typeof tokens.color.light;
