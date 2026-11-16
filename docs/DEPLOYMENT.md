# Deployment guide

Nothing has been deployed yet. These are the steps to stand up each environment; every billable step is
yours to run and approve.

## 0. Prerequisites (per environment: dev, staging, prod)

1. Create GCP projects `gud-meal-dev`, `gud-meal-staging`, `gud-meal-prod` and **add Firebase** to each.
2. Link billing and create a **budget alert** (the bootstrap script prints the command).
3. In Firebase Console:
   - enable Authentication providers (Phone, Email/Password, Google)
   - register the Android and iOS apps (bundle `ng.gudmeal.gud_meal_customer` / `ng.gudmeal.gud_meal_rider`)
   - register **one Web app** for the three websites; its `apiKey` and `appId` become GitHub Environment
     variables (section 3)
   - set up App Check: Play Integrity, App Attest, and a **reCAPTCHA Enterprise** key for the website domains
     (section 5)
4. Payment providers: Paystack (and optionally Flutterwave) business accounts; use **test keys** for dev/staging.

## 1. Bootstrap infrastructure

```bash
infra/scripts/bootstrap-gcp.sh gud-meal-dev europe-west1
```

Add `--with-cloud-sql` to create the PostgreSQL instance (billed hourly — the script asks first). Then
store secrets (never in the repo):

```bash
printf '%s' 'postgresql+asyncpg://gudmeal_api:<password>@/gudmeal?host=/cloudsql/gud-meal-dev:europe-west1:gudmeal-sql' | gcloud secrets versions add api-database-url --data-file=-
```

Required secrets: `api-database-url`, `agents-database-url`, `agents-checkpoint-url`, `paystack-secret-key`,
`api-code-pepper`, `gemini-api-key`, `gemini-model` (a pinned stable Flash id — verify with
`services/agents/scripts/check_gemini_models.py`), `channel-token-secret` (a long random value, read by both
the API and the agents service). Optional: `flutterwave-*`, `google-maps-server-key` (bound by `deploy.sh` as soon
as it has a value; see [GOOGLE_MAPS.md](GOOGLE_MAPS.md)), and the `whatsapp-*` secrets when Gudy on WhatsApp is
switched on (section 4a).

```bash
openssl rand -base64 48 | tr -d '\n' | gcloud secrets versions add channel-token-secret --data-file=-
```

`deploy.sh` also sets the service identities: the agents service calls the API with its own Google-signed token
(`INTERNAL_AUTH_MODE=oidc`), and the API lists that account in `TRUSTED_SERVICE_ACCOUNTS` so Gudy's calls pass App
Check. That list does not open `/internal/*`, which stays limited to `gudmeal-tasks`.

**Service URLs.** Deploys use Cloud Run's deterministic URLs, `https://SERVICE-PROJECT_NUMBER.REGION.run.app`
([`infra/scripts/urls.sh`](../infra/scripts/urls.sh)). They are known before the first deploy, so the OIDC
audience, the CORS origins, the payment return page and the websites' build settings are right from the start.
The bootstrap script prints them.

## 2. Firebase rules and indexes

```bash
cd firebase && firebase deploy --only firestore,storage --project gud-meal-dev
```

## 3. CI/CD

- `.github/workflows/ci.yml` runs on every push/PR: API on SQLite and PostgreSQL, Alembic, agents, Firebase
  emulator rules tests, web builds, Flutter analyze/tests, and Docker image builds. The API image and the three
  website images are smoke-tested.
- `.github/workflows/deploy.yml` is manual (`workflow_dispatch`) per GitHub Environment. Configure Workload
  Identity Federation for the `gudmeal-deployer` service account and protect `production` with required
  reviewers.

GitHub Environment settings (per environment):

| Kind | Name | Value |
|---|---|---|
| Variable | `GCP_PROJECT_ID`, `GCP_REGION`, `ARTIFACT_REPO` | e.g. `gud-meal-dev`, `europe-west1`, `gudmeal` |
| Variable | `FIREBASE_API_KEY`, `FIREBASE_APP_ID` | the Firebase Web app's config (public values) |
| Variable | `FIREBASE_AUTH_DOMAIN` | optional; defaults to `<project>.firebaseapp.com` |
| Variable | `APP_CHECK_SITE_KEY` | reCAPTCHA Enterprise site key for the websites; **required for production** |
| Variable | `MAPS_BROWSER_KEY` | optional Maps JavaScript key, restricted to the website domains |
| Variable | `API_URL`, `AGENTS_URL`, `WEB_URL`, `PARTNER_URL`, `ADMIN_URL` | optional custom domains (default: the run.app URLs) |
| Secret | `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_DEPLOY_SERVICE_ACCOUNT` | Workload Identity Federation (no JSON keys) |

The deploy job builds five images with Cloud Build (API, agents and the three websites), runs
`alembic upgrade head` as a Cloud Run job, then runs `infra/scripts/deploy.sh`: resource limits, autoscaling
bounds, the Cloud SQL connector, Secret Manager bindings and the five Cloud Run services.

## 4. After the first deploy

Run the follow-up commands printed by the bootstrap script: Cloud Run invoker for `gudmeal-tasks`, the
Pub/Sub push subscription to `/internal/events` (with dead-letter topic) and Cloud Scheduler jobs for
`relay-outbox`, `reconcile-payments`, `sweep` and `renew-plus` (daily, Gud Meal Plus wallet renewals). Then set the Paystack webhook URL to
`https://<api-url>/v1/webhooks/paystack` and (optionally) restrict by Paystack's source IPs via
`PAYSTACK_WEBHOOK_IP_ALLOWLIST`.

## 4a. Gudy on WhatsApp (optional; paid Meta service)

WhatsApp Business messaging is billed by Meta per conversation, so it stays off (`WHATSAPP_ENABLED=false`) until
the owner approves the cost ([ADR-0017](adr/0017-gudy-on-whatsapp.md)). To switch it on:

1. In Meta Business Manager: verify the business, add a WhatsApp Business number with an approved display name,
   and create a system user with a **permanent access token** for the WhatsApp Business Account.
2. Store the secrets (the verify token is any long random value you choose):

   ```bash
   gcloud secrets versions add whatsapp-access-token --data-file=-   # paste the system-user token, then Ctrl-D
   gcloud secrets versions add whatsapp-app-secret --data-file=-     # Meta app → Settings → Basic → App secret
   openssl rand -hex 32 | tr -d '\n' | gcloud secrets versions add whatsapp-verify-token --data-file=-
   ```

3. Deploy with WhatsApp on (links in Gudy's messages point to the customer website automatically):

   ```bash
   WHATSAPP_ENABLED=true WHATSAPP_PHONE_NUMBER_ID=<id from Meta> WHATSAPP_BUSINESS_NUMBER='+234 …' \
     infra/scripts/deploy.sh <environment> <project> <region> <repo> <tag>
   ```

4. In the Meta app's WhatsApp → Configuration, set the callback URL to `https://<api-url>/v1/webhooks/whatsapp`,
   enter the verify token, and subscribe to the `messages` field. Meta's verification call must succeed.
5. Check it: send `HELP` from a phone, then link a test account from the app (Profile → Order on WhatsApp).

The bootstrap script also turns on Firestore TTL for `whatsapp_messages` and `whatsapp_link_codes` (field
`expire_at`), so de-duplication records and old link codes delete themselves.

## 5. Websites

The customer website, the partner dashboard and the Command Centre run on Cloud Run as `gudmeal-web`,
`gudmeal-partner` and `gudmeal-admin`.

- **Image.** [`infra/docker/web.Dockerfile`](../infra/docker/web.Dockerfile) builds one app (`APP=web`, `partner`
  or `admin`) with Next.js standalone output (`BUILD_STANDALONE=true`). It runs `node server.js` as a non-root
  user on port 8080.
- **Settings.** The browser settings (`NEXT_PUBLIC_*`) are compiled in at build time, so every environment has
  its own images. They are the API and Gudy URLs, the site's own URL, the Firebase web config, the App Check site
  key and the optional Maps browser key. Cloud Build gets them from the deploy workflow. They are public by
  design, so never put a secret there. The build stops if a required value is missing. The customer site also
  reads `API_URL` at run time for its server-rendered pages.
- **Service.** Public, scales to zero (production keeps one customer-site instance warm), and runs as the
  role-less `gudmeal-web` service account.
- **API side.** `deploy.sh` sets the API's and Gudy's `CORS_ORIGINS` to the three sites, the payment return page
  to `<website>/checkout/callback`, and `PUBLIC_WEB_URL` (links in WhatsApp messages).
- **Firebase.** Add the three `run.app` hosts (the bootstrap script prints them) to Authentication → Settings →
  Authorized domains, or signing in on the sites fails.
- **App Check.** With `APP_CHECK_SITE_KEY` set, the sites send an App Check token (reCAPTCHA Enterprise) with
  every signed-in API call. The production API enforces App Check, so the deploy workflow refuses a production
  build without the key. Register the key for the Firebase Web app and list the three domains on it.
- **Custom domains** (e.g. `gudmeal.ng`): map them with Cloud Run domain mapping or a load balancer, set the
  `*_URL` variables and redeploy. Then update the authorized domains, the reCAPTCHA key's domains and the Maps
  browser key's referrers.

To build an image yourself (CI does this for all three with demo settings):

```bash
docker build -f infra/docker/web.Dockerfile --build-arg APP=web --build-arg NEXT_PUBLIC_API_URL=https://<api> \
  --build-arg NEXT_PUBLIC_AGENTS_URL=https://<agents> --build-arg NEXT_PUBLIC_SITE_URL=https://<site> \
  --build-arg NEXT_PUBLIC_FIREBASE_API_KEY=<key> --build-arg NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=<project>.firebaseapp.com \
  --build-arg NEXT_PUBLIC_FIREBASE_PROJECT_ID=<project> --build-arg NEXT_PUBLIC_FIREBASE_APP_ID=<app id> -t gudmeal-web .
```

## 6. Mobile releases

```bash
flutter build appbundle --release --dart-define=API_URL=https://<api> --dart-define=AGENTS_URL=https://<agents> --dart-define=USE_FIREBASE_EMULATORS=false --dart-define=FIREBASE_API_KEY=<key> --dart-define=FIREBASE_APP_ID=<id> --dart-define=FIREBASE_PROJECT_ID=<project> --dart-define=FIREBASE_SENDER_ID=<sender>
```

Requires an upload keystore (`android/key.properties`, never committed) and Play Console setup; iOS needs an
Apple Developer account, signing certificates and App Store Connect. The apps do not send App Check tokens yet,
so they cannot use the production API (which enforces App Check) until they do (see [PROGRESS.md](PROGRESS.md)).

## 7. Rollback

`gcloud run services update-traffic <service> --to-revisions=<previous>=100` for any of the five services
(`gudmeal-api`, `gudmeal-agents`, `gudmeal-web`, `gudmeal-partner`, `gudmeal-admin`). Database migrations are
forward-only in production; ship a new migration to revert schema changes.
