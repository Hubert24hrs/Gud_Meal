import type { NextConfig } from "next";

const config: NextConfig = {
  // Cloud Run images (infra/docker/web.Dockerfile) build with BUILD_STANDALONE=true and run the self-contained
  // server. Next.js finds the monorepo root from package-lock.json, so hoisted node_modules are traced in.
  output: process.env.BUILD_STANDALONE === "true" ? "standalone" : undefined,
  reactStrictMode: true,
  transpilePackages: ["@gudmeal/ui", "@gudmeal/api-client", "@gudmeal/tokens"],
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "images.unsplash.com" },
      { protocol: "https", hostname: "firebasestorage.googleapis.com" },
      { protocol: "https", hostname: "storage.googleapis.com" },
    ],
  },
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "X-Frame-Options", value: "DENY" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          { key: "Permissions-Policy", value: "camera=(), microphone=(self), geolocation=(self)" },
        ],
      },
    ];
  },
};

export default config;
