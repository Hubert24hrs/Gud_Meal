# ADR-0022: The brand: logo, icons and colours

- **Status:** Accepted; the name in item 1 was superseded on 2026-11-19 by [ADR-0023](0023-yummy-chops.md)
  (the platform is now **Yummy Chops**)
- **Date:** 2026-11-18
- **Context owner:** owner's request of 2026-11-18: use their logo as the platform logo and the app icon, call the
  platform "GudMeals" (it was "Gud Meal" before), and redesign the whole platform in the logo's colours

## Decision

1. **The name** (history): on 2026-11-18 the platform was called GudMeals everywhere people read it. Since
   2026-11-19 it is Yummy Chops ([ADR-0023](0023-yummy-chops.md)), with the same rule: every name people read
   changes, identifiers that nobody reads keep their old spelling.
2. **One master logo**, `assets/brand/yummychops-logo.webp` (1254 px square: the owner's artwork, with the name
   lettered "Yummy Chops" since ADR-0023). Everything else is cut from it by `scripts/make-brand-assets.py`
   (needs Pillow and numpy), never redrawn:
   - the whole logo, as the owner asked: **both apps' icons** (Android launcher icons, the iOS icon sets, the
     browser builds' install icons), the websites' home-screen icon, the sign-in screens of both apps and all
     three websites (on a white tile, so it reads in dark mode too), the Android launch screen, the phone install
     page and link previews. The customer app's icon is the logo on white; the rider
     app's is the same logo on a white disc on chocolate brown, so the two apps are easy to tell apart on one
     phone. The logo is sized so every drawn pixel stays inside the circle that every launcher keeps (66dp of
     the 108dp adaptive layer; iOS rounds the corners; maskable web icons keep the middle 80%), so no mask cuts
     off the hat, the name, the rider or the badges;
   - the emblem (chef's hat on the cloche, with the arc and the leaf) beside the name: website headers and
     footers, the partner dashboard and the Command Centre;
   - the emblem alone: browser-tab icons (favicons), which are 16 to 32 pixels, too small for the whole logo;
   - the rider on the scooter: the rider app's browser-tab icon.
   The cut-outs lose the white around the drawing and keep the white that is part of it (the hat). The name
   loses all its white, so it also sits on dark backgrounds; a second copy has a cream "Yummy" for dark
   backgrounds (dark mode, the Command Centre's sidebar).
3. **Colours from the logo** (`packages/tokens/tokens.json`, regenerated to CSS, TypeScript and Dart):
   red `#E0040B` ("Chops") for actions and links; chocolate brown `#3A0D05` ("Yummy", the cloche) for text tones
   and secondary surfaces; orange-gold `#F5A21A` (the arc and swoosh) as the accent; leaf green `#2E8B1E` for
   success and money coming in. The header gradient runs from `#F25C22` to the red, like the logo's swoosh. The
   dark theme uses lighter versions of the same colours on a very dark brown.
4. **The assistant (Yummy, first called Gudy) wears the cloche's colours:** a chocolate-brown disc with a gold antenna instead of blue.
5. **Headings use Nunito** on the websites, a heavy rounded face like the logo's lettering (body text stays Plus
   Jakarta Sans). The apps keep the platform font.

## Consequences

- To change the logo, replace `yummychops-logo.webp` and run the script; if the new artwork is laid out
  differently, adjust the cut-out regions in the script (`emblem`, `wordmark`, `rider`).
- The first logo (`gud-meal-logo.jpg`), its icon script (`make-app-icons.ps1`) and the GudMeals logo files are
  gone; they are in the git history.
- The store listings will need the logo at full size; the script already writes the iOS icon set.
