#!/usr/bin/env bash
# Deploy gudmeal-api and gudmeal-agents to Cloud Run.
# Usage: infra/scripts/deploy.sh <environment> <project> <region> <artifact-repo> <tag>
# Secrets are referenced from Secret Manager (never passed on the command line).
set -euo pipefail

ENVIRONMENT="$1"; PROJECT="$2"; REGION="$3"; REPO="$4"; TAG="$5"
IMG="$REGION-docker.pkg.dev/$PROJECT/$REPO"
SQL="$PROJECT:$REGION:gudmeal-sql"

case "$ENVIRONMENT" in
  production) MIN=1; MAX=20 ;;
  staging)    MIN=0; MAX=4 ;;
  *)          MIN=0; MAX=2 ;;
esac

API_URL=$(gcloud run services describe gudmeal-api --project "$PROJECT" --region "$REGION" --format 'value(status.url)' 2>/dev/null || true)
API_URL=${API_URL:-"https://gudmeal-api-pending.a.run.app"}
AGENTS_URL=$(gcloud run services describe gudmeal-agents --project "$PROJECT" --region "$REGION" --format 'value(status.url)' 2>/dev/null || true)
AGENTS_URL=${AGENTS_URL:-"https://gudmeal-agents-pending.a.run.app"}

# Gudy on WhatsApp (ADR-0017) uses Meta's paid WhatsApp Business messaging, so it stays off until the owner has
# approved the cost and finished the Meta setup. To switch it on, fill the whatsapp-* secrets and run this script
# with WHATSAPP_ENABLED=true, WHATSAPP_PHONE_NUMBER_ID, WHATSAPP_BUSINESS_NUMBER and PUBLIC_WEB_URL set.
WHATSAPP_ENV="WHATSAPP_ENABLED=false"
WHATSAPP_SECRETS=""
if [[ "${WHATSAPP_ENABLED:-false}" == "true" ]]; then
  : "${WHATSAPP_PHONE_NUMBER_ID:?set WHATSAPP_PHONE_NUMBER_ID}" "${WHATSAPP_BUSINESS_NUMBER:?set WHATSAPP_BUSINESS_NUMBER}" "${PUBLIC_WEB_URL:?set PUBLIC_WEB_URL}"
  WHATSAPP_ENV="WHATSAPP_ENABLED=true,WHATSAPP_PROVIDER=cloud,WHATSAPP_PHONE_NUMBER_ID=$WHATSAPP_PHONE_NUMBER_ID,WHATSAPP_BUSINESS_NUMBER=$WHATSAPP_BUSINESS_NUMBER,PUBLIC_WEB_URL=$PUBLIC_WEB_URL"
  WHATSAPP_SECRETS=",WHATSAPP_ACCESS_TOKEN=whatsapp-access-token:latest,WHATSAPP_APP_SECRET=whatsapp-app-secret:latest,WHATSAPP_VERIFY_TOKEN=whatsapp-verify-token:latest"
fi

echo "==> Deploying gudmeal-api ($ENVIRONMENT, min=$MIN max=$MAX)"
gcloud run deploy gudmeal-api --project "$PROJECT" --region "$REGION" \
  --image "$IMG/gudmeal-api:$TAG" \
  --service-account "gudmeal-api@$PROJECT.iam.gserviceaccount.com" \
  --cpu 1 --memory 512Mi --concurrency 40 --timeout 60 \
  --min-instances "$MIN" --max-instances "$MAX" \
  --set-cloudsql-instances "$SQL" \
  --allow-unauthenticated \
  --set-env-vars "ENVIRONMENT=$ENVIRONMENT,DATA_BACKEND=firestore,SEED_DEMO_DATA=false,GCP_PROJECT_ID=$PROJECT,FIREBASE_PROJECT_ID=$PROJECT,EVENT_BUS=pubsub,TASK_QUEUE=cloudtasks,NOTIFIER=fcm,INTERNAL_AUTH_MODE=oidc,CLOUD_TASKS_LOCATION=$REGION,CLOUD_TASKS_SERVICE_ACCOUNT=gudmeal-tasks@$PROJECT.iam.gserviceaccount.com,INTERNAL_OIDC_AUDIENCE=$API_URL,PUBLIC_BASE_URL=$API_URL,APP_CHECK_ENFORCED=$([ "$ENVIRONMENT" = production ] && echo true || echo false),AGENTS_BASE_URL=$AGENTS_URL,$WHATSAPP_ENV" \
  --set-env-vars "^;^INTERNAL_OIDC_SERVICE_ACCOUNTS=[\"gudmeal-tasks@$PROJECT.iam.gserviceaccount.com\"];TRUSTED_SERVICE_ACCOUNTS=[\"gudmeal-agents@$PROJECT.iam.gserviceaccount.com\"]" \
  --set-secrets "DATABASE_URL=api-database-url:latest,PAYSTACK_SECRET_KEY=paystack-secret-key:latest,CODE_PEPPER=api-code-pepper:latest,CHANNEL_TOKEN_SECRET=channel-token-secret:latest$WHATSAPP_SECRETS"

echo "==> Deploying gudmeal-agents"
gcloud run deploy gudmeal-agents --project "$PROJECT" --region "$REGION" \
  --image "$IMG/gudmeal-agents:$TAG" \
  --service-account "gudmeal-agents@$PROJECT.iam.gserviceaccount.com" \
  --cpu 1 --memory 1Gi --concurrency 20 --timeout 120 \
  --min-instances 0 --max-instances "$MAX" \
  --set-cloudsql-instances "$SQL" \
  --allow-unauthenticated \
  --set-env-vars "ENVIRONMENT=$ENVIRONMENT,API_BASE_URL=$API_URL,FIREBASE_PROJECT_ID=$PROJECT,CHECKPOINTER=postgres,CHECK_TOKEN_REVOCATION=true,LANGSMITH_TRACING=false,INTERNAL_AUTH_MODE=oidc" \
  --set-secrets "GOOGLE_API_KEY=gemini-api-key:latest,GEMINI_MODEL=gemini-model:latest,DATABASE_URL=agents-database-url:latest,CHECKPOINT_POSTGRES_URL=agents-checkpoint-url:latest,CHANNEL_TOKEN_SECRET=channel-token-secret:latest"

echo "==> Done. Roll back with: gcloud run services update-traffic gudmeal-api --to-revisions=<previous>=100 --region $REGION --project $PROJECT"
