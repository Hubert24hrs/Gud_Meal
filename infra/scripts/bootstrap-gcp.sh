#!/usr/bin/env bash
# One-time bootstrap of a Gud Meal environment in an EXISTING Google Cloud project that already has
# Firebase added and billing enabled. Run it yourself, per environment (dev → staging → prod):
#
#   infra/scripts/bootstrap-gcp.sh gud-meal-dev europe-west1
#   infra/scripts/bootstrap-gcp.sh gud-meal-dev europe-west1 --with-cloud-sql   # creates a billable Cloud SQL instance
#
# The script is idempotent where gcloud allows (existing resources are skipped) and NEVER creates
# Cloud SQL unless --with-cloud-sql is passed and you confirm the cost prompt.
set -euo pipefail

PROJECT="${1:?project id required, e.g. gud-meal-dev}"
REGION="${2:-europe-west1}"
WITH_SQL="${3:-}"
ENV_NAME="${PROJECT##*-}"   # dev | staging | prod

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
exists() { "$@" >/dev/null 2>&1; }

say "Checking billing for $PROJECT"
BILLING=$(gcloud beta billing projects describe "$PROJECT" --format='value(billingEnabled)' 2>/dev/null || echo "unknown")
echo "billingEnabled=$BILLING"
if [[ "$BILLING" != "True" ]]; then
  echo "Billing is not enabled (or not visible to you). Enable billing and create a budget alert first." >&2
  exit 1
fi
cat <<EOF

This will enable APIs and create (mostly free-tier / pay-per-use) resources in $PROJECT ($REGION):
  Artifact Registry, service accounts, Pub/Sub topic, Cloud Tasks queue, Cloud Scheduler jobs,
  Secret Manager secret placeholders and a Firestore database.
Cloud Run, Pub/Sub, Tasks, Scheduler and Firestore bill per use. See docs/COST_ESTIMATE.md.
EOF
read -r -p "Type the project id to continue: " CONFIRM
[[ "$CONFIRM" == "$PROJECT" ]] || { echo "Aborted."; exit 1; }

gcloud config set project "$PROJECT" >/dev/null

say "Enabling APIs"
gcloud services enable run.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com \
  secretmanager.googleapis.com pubsub.googleapis.com cloudtasks.googleapis.com cloudscheduler.googleapis.com \
  firestore.googleapis.com iam.googleapis.com iamcredentials.googleapis.com sqladmin.googleapis.com \
  monitoring.googleapis.com logging.googleapis.com firebase.googleapis.com identitytoolkit.googleapis.com \
  fcm.googleapis.com firebaseappcheck.googleapis.com

say "Artifact Registry"
exists gcloud artifacts repositories describe gudmeal --location "$REGION" ||
  gcloud artifacts repositories create gudmeal --repository-format docker --location "$REGION" \
    --description "Gud Meal service images"

say "Service accounts (least privilege)"
for sa in gudmeal-api gudmeal-agents gudmeal-tasks gudmeal-deployer; do
  exists gcloud iam service-accounts describe "$sa@$PROJECT.iam.gserviceaccount.com" ||
    gcloud iam service-accounts create "$sa" --display-name "$sa"
done
bind() { gcloud projects add-iam-policy-binding "$PROJECT" --member "serviceAccount:$1@$PROJECT.iam.gserviceaccount.com" --role "$2" --condition None >/dev/null; }
for role in roles/datastore.user roles/cloudsql.client roles/secretmanager.secretAccessor roles/pubsub.publisher \
            roles/cloudtasks.enqueuer roles/firebaseauth.admin roles/firebasecloudmessaging.admin roles/logging.logWriter \
            roles/monitoring.metricWriter; do
  bind gudmeal-api "$role"
done
for role in roles/cloudsql.client roles/secretmanager.secretAccessor roles/logging.logWriter roles/monitoring.metricWriter; do
  bind gudmeal-agents "$role"
done
for role in roles/run.admin roles/cloudbuild.builds.editor roles/artifactregistry.writer roles/iam.serviceAccountUser; do
  bind gudmeal-deployer "$role"
done
# The API enqueues Cloud Tasks that authenticate as gudmeal-tasks.
gcloud iam service-accounts add-iam-policy-binding "gudmeal-tasks@$PROJECT.iam.gserviceaccount.com" \
  --member "serviceAccount:gudmeal-api@$PROJECT.iam.gserviceaccount.com" --role roles/iam.serviceAccountUser >/dev/null

say "Firestore (Native mode)"
exists gcloud firestore databases describe --database="(default)" ||
  gcloud firestore databases create --location="$REGION" --type=firestore-native
echo "Deploy rules & indexes with: (cd firebase && firebase deploy --only firestore,storage --project $PROJECT)"

say "Pub/Sub, Cloud Tasks"
exists gcloud pubsub topics describe gudmeal-domain-events || gcloud pubsub topics create gudmeal-domain-events
exists gcloud pubsub topics describe gudmeal-domain-events-dlq || gcloud pubsub topics create gudmeal-domain-events-dlq
exists gcloud tasks queues describe gudmeal-default --location "$REGION" ||
  gcloud tasks queues create gudmeal-default --location "$REGION" --max-attempts 8 --min-backoff 5s --max-backoff 300s

say "Secret Manager placeholders (add values yourself: gcloud secrets versions add NAME --data-file=-)"
for s in api-database-url agents-database-url agents-checkpoint-url paystack-secret-key flutterwave-secret-key \
         flutterwave-secret-hash api-code-pepper gemini-api-key gemini-model google-maps-api-key; do
  exists gcloud secrets describe "$s" || gcloud secrets create "$s" --replication-policy automatic
done

if [[ "$WITH_SQL" == "--with-cloud-sql" ]]; then
  TIER=$([[ "$ENV_NAME" == "prod" ]] && echo db-custom-2-7680 || echo db-custom-1-3840)
  AVAIL=$([[ "$ENV_NAME" == "prod" ]] && echo REGIONAL || echo ZONAL)
  cat <<EOF

Cloud SQL for PostgreSQL 16 — tier $TIER, availability $AVAIL, backups + point-in-time recovery.
This is BILLED HOURLY even when idle (see docs/COST_ESTIMATE.md).
EOF
  read -r -p "Create the Cloud SQL instance now? (yes/no) " OK
  if [[ "$OK" == "yes" ]]; then
    exists gcloud sql instances describe gudmeal-sql ||
      gcloud sql instances create gudmeal-sql --database-version POSTGRES_16 --region "$REGION" --tier "$TIER" \
        --availability-type "$AVAIL" --backup-start-time 02:00 --enable-point-in-time-recovery \
        --storage-auto-increase --deletion-protection
    for db in gudmeal gudmeal_agents; do
      exists gcloud sql databases describe "$db" --instance gudmeal-sql || gcloud sql databases create "$db" --instance gudmeal-sql
    done
    echo "Create DB users with generated passwords and store the connection URLs in Secret Manager:"
    echo "  gcloud sql users create gudmeal_api --instance gudmeal-sql --password=<generated>"
  fi
fi

cat <<EOF

Next steps (after the first deploy, when the API URL is known):
  API_URL=\$(gcloud run services describe gudmeal-api --region $REGION --format 'value(status.url)')
  gcloud run services add-iam-policy-binding gudmeal-api --region $REGION \\
    --member serviceAccount:gudmeal-tasks@$PROJECT.iam.gserviceaccount.com --role roles/run.invoker
  gcloud pubsub subscriptions create gudmeal-events-push --topic gudmeal-domain-events \\
    --push-endpoint "\$API_URL/internal/events" --push-auth-service-account gudmeal-tasks@$PROJECT.iam.gserviceaccount.com \\
    --push-auth-token-audience "\$API_URL" --dead-letter-topic gudmeal-domain-events-dlq --max-delivery-attempts 10
  for job in "relay-outbox|* * * * *" "reconcile-payments|*/10 * * * *" "sweep|*/5 * * * *" "renew-plus|0 7 * * *"; do
    gcloud scheduler jobs create http "gudmeal-\${job%%|*}" --location $REGION --schedule "\${job##*|}" \\
      --uri "\$API_URL/internal/jobs/\${job%%|*}" --http-method POST \\
      --oidc-service-account-email gudmeal-tasks@$PROJECT.iam.gserviceaccount.com --oidc-token-audience "\$API_URL"
  done
  Budget alert: gcloud billing budgets create --billing-account <ACCOUNT_ID> --display-name "gudmeal-$ENV_NAME" \\
    --budget-amount 100USD --threshold-rule percent=0.5 --threshold-rule percent=0.9 --threshold-rule percent=1.0
EOF
