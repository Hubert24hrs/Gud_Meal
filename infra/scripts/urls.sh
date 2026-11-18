# Public URLs of GudMeals' Cloud Run services. Sourced (not run) by deploy.sh and the deploy workflow, with
# PROJECT and REGION set.
#
# Cloud Run's deterministic URLs (https://SERVICE-PROJECT_NUMBER.REGION.run.app) are known before the first deploy,
# so the OIDC audience, the CORS origins and the websites' build settings are right from the start. To use custom
# domains, set API_URL, AGENTS_URL, WEB_URL, PARTNER_URL or ADMIN_URL before sourcing this file.
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT" --format 'value(projectNumber)')
run_url() { printf 'https://%s-%s.%s.run.app' "$1" "$PROJECT_NUMBER" "$REGION"; }
API_URL=${API_URL:-$(run_url gudmeal-api)}
AGENTS_URL=${AGENTS_URL:-$(run_url gudmeal-agents)}
WEB_URL=${WEB_URL:-$(run_url gudmeal-web)}
PARTNER_URL=${PARTNER_URL:-$(run_url gudmeal-partner)}
ADMIN_URL=${ADMIN_URL:-$(run_url gudmeal-admin)}
