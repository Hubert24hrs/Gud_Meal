# ADR-0023: The name Yummy Chops, the assistant Yummy, and the yummy247.com domain

- **Status:** Accepted
- **Date:** 2026-11-19
- **Context owner:** owner's request of 2026-11-19: change the platform's name from GudMeals to "Yummy Chops"
  everywhere, including the logo and the app icon; the owner will buy the domain `yummy247.com` for it later.
  Supersedes the name in [ADR-0022](0022-brand.md); the logo, icons and colours of ADR-0022 stay.

## Decision

1. **The name is Yummy Chops** everywhere people read it: the app names ("Yummy Chops", "Yummy Chops Rider" on
   Android, iOS and the browser builds; "Yummy Rider" where a browser build needs a short name), page titles,
   website headers, Yummy Chops Partner and the Command Centre, the assistant's words, WhatsApp messages, receipts (headed
   YUMMY CHOPS), notifications, payment descriptions, the phone download page and its files (`yummy-chops.apk`,
   `yummy-chops-rider.apk`), the "download my data" file and the docs. Membership is **Yummy Chops Plus** and
   the loyalty points are **Yummy points** (they were "Gud points"). The assistant understands the new names offline too.
2. **The logo keeps the owner's artwork; only its lettering changed.** "GudMeals" was replaced by "Yummy Chops":
   "Yummy" in the dark brown and "Chops" in the red of the old lettering, with the same top-to-bottom shading and
   forward slant, in Nunito at its heaviest weight (the websites' heading face). It spans the old lettering's
   width and sits a little higher, so the tails of "y" and "p" clear the red underline. The hat, cloche, arc,
   leaf, underline, tagline, rider and badges are unchanged. The result is the master
   `assets/brand/yummychops-logo.webp` (lossless); the app icons, the website headers, the favicons and every
   other logo file are made from it by `scripts/make-brand-assets.py` (ADR-0022).
3. **Numbers people see start with YC** (Yummy Chops) instead of GM: receipts `YC-<order code>`, payment
   references `YC-…`, vouchers `YCP-` (from points), `YCR-` (referral reward) and `YCF-` (a friend's welcome
   gift). Nothing reads a payment's kind from its prefix, so older references still verify.
4. **The domain will be `yummy247.com`.** Until the owner buys it and its mailbox exists, these are placeholders:
   the support email `support@yummy247.com`, and `…@customers.yummy247.com` for customers without an email
   address (the payment provider requires one). The planned addresses: `yummy247.com` and `www` (customer
   website), `partner.`, `admin.`, `api.` and `assistant.` (the assistant) (docs/DEPLOYMENT.md). The sites keep using
   their Cloud Run addresses until the domain is mapped (`NEXT_PUBLIC_SITE_URL` and the `*_URL` settings).
   The planned Google Cloud projects are `yummy-chops-dev`, `yummy-chops-staging` and `yummy-chops-prod`
   (none existed yet, and a project id can never change; Firebase shows it during Google sign-in).
5. **Demo accounts** on the local test server are `@yummychops.test` (customer, friend, rider, owner, kitchen,
   support, finance, hub, admin), with the same password as before.
6. **The assistant is called Yummy** (it was Gudy, a name made from "Gud Meal"; the owner renamed it right after
   the platform). The floating button ("Hi, I'm Yummy!"), the assistant screen, its replies in all five
   languages, its WhatsApp messages, the system prompt and the docs say Yummy. Its code keeps the old spelling
   (`GudyFab`, `GudyAvatar`, `onAskGudy`, `ui/gudy.dart`, `'gudy-fab'`, test names), and the WhatsApp ADR is now
   [0017-assistant-on-whatsapp.md](0017-assistant-on-whatsapp.md), a file name that no future rename touches.
7. **Kept as they are:**
   - identifiers nobody reads: the Python packages `gudmeal_api` and `gudmeal_agents`, the npm scope
     `@gudmeal/*`, Dart classes such as `GudMealApi`, the emulator project `demo-gudmeal`, browser storage keys,
     and the API's health name `gudmeal-api` (the installed test apps look for it to find the test server);
   - the app ids `ng.gudmeal.gud_meal_customer` and `ng.gudmeal.gud_meal_rider` (and the iOS bundle ids). With the
     same ids the new test builds install over the old ones. They become permanent with the first store release,
     so decide before then whether to move them to `com.yummy247.*` (a phone then treats them as new apps);
   - the GitHub repository `Gud_Meal` and the local folder name.

## Consequences

- Install both test apps again: the icon, the name and the logo change; signing in uses the new demo emails.
- Receipts and vouchers made before the rename keep their GM numbers.
- When the domain is bought: map it, create the mailbox, set `SUPPORT_EMAIL` if it differs, and add the
  addresses to Firebase's authorized domains, the reCAPTCHA key and the Maps browser key (docs/DEPLOYMENT.md).
