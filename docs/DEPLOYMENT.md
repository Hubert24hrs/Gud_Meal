# Deployment guide

Nothing has been deployed yet. These are the steps to stand up each environment; every billable step is
yours to run and approve.

## 0. Prerequisites (per environment: dev, staging, prod)

1. Create GCP projects `gud-meal-dev`, `gud-meal-staging`, `gud-meal-prod` and **add Firebase** to each.
2. Link billing and create a **budget alert** (the bootstrap script prints the command).
3. In Firebase Console: enable Authentication providers (Phone, Email/Password, Google), register the Android
   and iOS apps (bundle `ng.gudmeal.gud_meal_customer` / `ng.gudmeal.gud_meal_rider`) and the web apps,
   enable App Check (Play Integrity, App Attest, reCAPTCHA Enterprise).
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
the API and the agents service), optionally `flutterwave-*`, `google-maps-api-key`, and the `whatsapp-*`
secrets when Gudy on WhatsApp is switched on (section 4a).

```bash
openssl rand -base64 48 | tr -d '\n' | gcloud secrets versions add channel-token-secret --data-file=-
```

`deploy.sh` also sets the service identities: the agents service calls the API with its own Google-signed token
(`INTERNAL_AUTH_MODE=oidc`), and the API lists that account in `TRUSTED_SERVICE_ACCOUNTS` so Gudy's calls pass App
Check. That list does not open `/internal/*`, which stays limited to `gudmeal-tasks`.

## 2. Firebase rules and indexes

```bash
cd firebase && firebase deploy --only firestore,storage --project gud-meal-dev
```

## 3. CI/CD

- `.github/workflows/ci.yml` runs on every push/PR (API on SQLite and PostgreSQL, Alembic, agents, Firebase
  emulator rules tests, web builds, Flutter analyze/tests, Docker image builds).
- `.github/workflows/deploy.yml` is manual (`workflow_dispatch`) per GitHub Environment. Configure Workload
  Identity Federation for the `gudmeal-deployer` service account and set `GCP_PROJECT_ID`, `GCP_REGION`,
  `ARTIFACT_REPO` variables plus `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_DEPLOY_SERVICE_ACCOUNT` secrets.
  Protect `production` with required reviewers.

The deploy job builds images with Cloud Build, runs `alembic upgrade head` as a Cloud Run job, then runs
`infra/scripts/deploy.sh` (resource limits, autoscaling bounds, Cloud SQL connector, Secret Manager bindings).

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

3. Deploy with WhatsApp on:

   ```bash
   WHATSAPP_ENABLED=true WHATSAPP_PHONE_NUMBER_ID=<id from Meta> WHATSAPP_BUSINESS_NUMBER='+234 …' \
     PUBLIC_WEB_URL=https://<website> infra/scripts/deploy.sh <environment> <project> <region> <repo> <tag>
   ```

4. In the Meta app's WhatsApp → Configuration, set the callback URL to `https://<api-url>/v1/webhooks/whatsapp`,
   enter the verify token, and subscribe to the `messages` field. Meta's verification call must succeed.
5. Check it: send `HELP` from a phone, then link a test account from the app (Profile → Order on WhatsApp).

The bootstrap script also turns on Firestore TTL for `whatsapp_messages` and `whatsapp_link_codes` (field
`expire_at`), so de-duplication records and old link codes delete themselves.

## 5. Web apps

The Next.js apps deploy to Cloud Run (or Firebase App Hosting) with `NEXT_PUBLIC_*` values from the Firebase
web config and the API/agents URLs. Run `npm run build` in CI first.

## 6. Mobile releases

```bash
flutter build appbundle --release --dart-define=API_URL=https://<api> --dart-define=AGENTS_URL=https://<agents> --dart-define=USE_FIREBASE_EMULATORS=false --dart-define=FIREBASE_API_KEY=<key> --dart-define=FIREBASE_APP_ID=<id> --dart-define=FIREBASE_PROJECT_ID=<project> --dart-define=FIREBASE_SENDER_ID=<sender>
```

Requires an upload keystore (`android/key.properties`, never committed) and Play Console setup; iOS needs an
Apple Developer account, signing certificates and App Store Connect.

## 7. Rollback

`gcloud run services update-traffic gudmeal-api --to-revisions=<previous>=100` (same for agents).
Database migrations are forward-only in production; ship a new migration to revert schema changes.
