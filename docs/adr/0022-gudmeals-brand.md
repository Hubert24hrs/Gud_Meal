# ADR-0022: The GudMeals brand: name, logo, icons and colours

- **Status:** Accepted
- **Date:** 2026-11-18
- **Context owner:** owner's request of 2026-11-18: use their logo as the platform logo and the app icon, call the
  platform "GudMeals" (not "Gud Meal"), and redesign the whole platform in the logo's colours

## Decision

1. **The name is GudMeals** everywhere people read it: app names ("GudMeals", "GudMeals Rider"), page titles,
   headers, Gudy's words, WhatsApp messages, receipts, notifications, payment descriptions and the docs.
   Identifiers that nobody reads keep the old spelling (`gudmeal_api`, `GudMealApi`, `demo-gudmeal`,
   `gudmeal.test` accounts): renaming them would touch every import and stored id for no visible gain.
2. **One master logo**, `assets/brand/gudmeals-logo.webp` (1254 px square, from the owner). Everything else is
   cut from it by `scripts/make-brand-assets.py` (needs Pillow), never redrawn:
   - the whole logo: app sign-in screens, the Android launch screen, the phone install page;
   - the emblem (chef's hat on the cloche, with the arc and the leaf) beside the name: website headers and
     footers, the partner dashboard and the Command Centre;
   - the emblem alone: the customer app's icon and the websites' favicons;
   - the rider on the scooter, on a white disc on chocolate brown: the rider app's icon, so the two apps are easy
     to tell apart on one phone.
   The cut-outs lose the white around the drawing and keep the white that is part of it (the hat). A second copy
   of the name has a cream "Gud" for dark backgrounds (dark mode, the Command Centre's sidebar).
3. **Colours from the logo** (`packages/tokens/tokens.json`, regenerated to CSS, TypeScript and Dart):
   red `#E0040B` ("Meals") for actions and links; chocolate brown `#3A0D05` ("Gud", the cloche) for text tones
   and secondary surfaces; orange-gold `#F5A21A` (the arc and swoosh) as the accent; leaf green `#2E8B1E` for
   success and money coming in. The header gradient runs from `#F25C22` to the red, like the logo's swoosh. The
   dark theme uses lighter versions of the same colours on a very dark brown.
4. **Gudy wears the cloche's colours:** a chocolate-brown disc with a gold antenna instead of blue.
5. **Headings use Nunito** on the websites, a heavy rounded face like the logo's lettering (body text stays Plus
   Jakarta Sans). The apps keep the platform font.

## Consequences

- To change the logo, replace `gudmeals-logo.webp` and run the script; if the new artwork is laid out
  differently, adjust the cut-out regions at the top of the script.
- The old logo (`gud-meal-logo.jpg`) and its icon script (`make-app-icons.ps1`) are gone.
- The store listings will need the logo at full size; the script already writes the iOS icon set.
