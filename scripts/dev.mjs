#!/usr/bin/env node
// Local development launcher: `node scripts/dev.mjs <api|agents|auth>`.
// Uses safe local defaults (memory data + payment sandbox + Firebase Auth emulator). Real keys go in .env files.
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const isWin = process.platform === "win32";
const py = (svc) => join(root, "services", svc, ".venv", isWin ? "Scripts/python.exe" : "bin/python");

const shared = {
  ENVIRONMENT: "local",
  FIREBASE_PROJECT_ID: "demo-gudmeal",
  FIREBASE_AUTH_EMULATOR_HOST: process.env.FIREBASE_AUTH_EMULATOR_HOST ?? "127.0.0.1:9099",
  PYTHONUNBUFFERED: "1",
};

const targets = {
  api: {
    cmd: py("api"),
    args: ["-m", "uvicorn", "--factory", "gudmeal_api.main:app_factory", "--port", "8000"],
    cwd: join(root, "services/api"),
    env: {
      DATA_BACKEND: "memory", SEED_DEMO_DATA: "true", DATABASE_URL: "sqlite+aiosqlite:///./gudmeal_local.db",
      PUBLIC_BASE_URL: "http://localhost:8000", PAYMENT_CALLBACK_URL: "http://localhost:3000/checkout/callback",
      INTERNAL_SHARED_SECRET: "local-dev-only", CHECK_TOKEN_REVOCATION: "false",
    },
  },
  agents: {
    cmd: py("agents"),
    args: ["-m", "uvicorn", "--factory", "gudmeal_agents.main:app_factory", "--port", "8100"],
    cwd: join(root, "services/agents"),
    env: { API_BASE_URL: "http://localhost:8000", CHECKPOINTER: "sqlite" },
  },
  // Serves the last `flutter build web` of the customer app (run that first) for browser testing.
  "customer-web": {
    cmd: isWin ? "python" : "python3",
    args: ["-m", "http.server", "5050", "--bind", "127.0.0.1", "--directory", join(root, "mobile/customer/build/web")],
    cwd: root,
    env: {},
  },
  auth: {
    cmd: isWin ? "firebase.cmd" : "firebase",
    args: ["--non-interactive", "emulators:start", "--only", "auth", "--project", "demo-gudmeal"],
    cwd: join(root, "firebase"),
    env: {},
    shell: isWin,
  },
};

const name = process.argv[2];
const target = targets[name];
if (!target) {
  console.error(`usage: node scripts/dev.mjs <${Object.keys(targets).join("|")}>`);
  process.exit(2);
}
if (target.cmd.endsWith("python.exe") || target.cmd.endsWith("/python")) {
  if (!existsSync(target.cmd)) {
    console.error(`Missing virtualenv: run \`uv sync\` in ${target.cwd}`);
    process.exit(1);
  }
}
const child = spawn(target.cmd, target.args, {
  cwd: target.cwd, stdio: "inherit", shell: target.shell ?? false,
  env: { ...process.env, ...shared, ...target.env },
});
child.on("exit", (code) => process.exit(code ?? 0));
for (const sig of ["SIGINT", "SIGTERM"]) process.on(sig, () => child.kill(sig));
