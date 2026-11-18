# GudMeals websites for Cloud Run: the customer site (APP=web), the partner dashboard (APP=partner) and the
# Command Centre (APP=admin). Build from the repository root, one image per app:
#
#   docker build -f infra/docker/web.Dockerfile --build-arg APP=web \
#     --build-arg NEXT_PUBLIC_API_URL=https://... --build-arg NEXT_PUBLIC_FIREBASE_API_KEY=... -t gudmeal-web .
#
# NEXT_PUBLIC_* values are compiled into the browser code, so every environment gets its own images. They are
# public by design: service URLs, the Firebase web config, and the App Check and Maps browser keys (restricted to
# the sites' domains). Never pass a secret here.

FROM node:22-slim AS build
WORKDIR /repo
ENV NEXT_TELEMETRY_DISABLED=1
# Workspace manifests first, so the dependency layer is reused until package-lock.json changes.
COPY package.json package-lock.json ./
COPY packages/tokens/package.json packages/tokens/
COPY packages/api-client/package.json packages/api-client/
COPY packages/ui/package.json packages/ui/
COPY apps/web/package.json apps/web/
COPY apps/partner/package.json apps/partner/
COPY apps/admin/package.json apps/admin/
COPY firebase/package.json firebase/
RUN npm ci --no-audit --no-fund
COPY packages ./packages
COPY apps ./apps

ARG APP
ARG NEXT_PUBLIC_API_URL
ARG NEXT_PUBLIC_AGENTS_URL
ARG NEXT_PUBLIC_SITE_URL
ARG NEXT_PUBLIC_FIREBASE_API_KEY
ARG NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN
ARG NEXT_PUBLIC_FIREBASE_PROJECT_ID
ARG NEXT_PUBLIC_FIREBASE_APP_ID
ARG NEXT_PUBLIC_APP_CHECK_SITE_KEY
ARG NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL} \
    NEXT_PUBLIC_AGENTS_URL=${NEXT_PUBLIC_AGENTS_URL} \
    NEXT_PUBLIC_SITE_URL=${NEXT_PUBLIC_SITE_URL} \
    NEXT_PUBLIC_FIREBASE_API_KEY=${NEXT_PUBLIC_FIREBASE_API_KEY} \
    NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=${NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN} \
    NEXT_PUBLIC_FIREBASE_PROJECT_ID=${NEXT_PUBLIC_FIREBASE_PROJECT_ID} \
    NEXT_PUBLIC_FIREBASE_APP_ID=${NEXT_PUBLIC_FIREBASE_APP_ID} \
    NEXT_PUBLIC_APP_CHECK_SITE_KEY=${NEXT_PUBLIC_APP_CHECK_SITE_KEY} \
    NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY=${NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY} \
    NEXT_PUBLIC_USE_FIREBASE_EMULATORS=false \
    BUILD_STANDALONE=true
# Refuse to build an image that would point at nothing: these values have no safe default in the cloud.
RUN case "$APP" in web|partner|admin) ;; *) echo "APP must be web, partner or admin" >&2; exit 1 ;; esac \
 && for v in NEXT_PUBLIC_API_URL NEXT_PUBLIC_AGENTS_URL NEXT_PUBLIC_SITE_URL NEXT_PUBLIC_FIREBASE_API_KEY \
             NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN NEXT_PUBLIC_FIREBASE_PROJECT_ID NEXT_PUBLIC_FIREBASE_APP_ID; do \
      eval "test -n \"\$$v\"" || { echo "Missing build arg $v" >&2; exit 1; }; \
    done \
 && npm run build -w "@gudmeal/$APP"

FROM node:22-slim
ARG APP
ENV NODE_ENV=production NEXT_TELEMETRY_DISABLED=1 PORT=8080 HOSTNAME=0.0.0.0
WORKDIR /srv
# The standalone server and the traced node_modules, then the static assets it serves itself. (The apps have no
# public/ folder; copy apps/$APP/public next to server.js if one is added.)
COPY --from=build --chown=node:node /repo/apps/${APP}/.next/standalone ./
COPY --from=build --chown=node:node /repo/apps/${APP}/.next/static ./apps/${APP}/.next/static
WORKDIR /srv/apps/${APP}
USER node
EXPOSE 8080
CMD ["node", "server.js"]
