#!/usr/bin/env node
// Local development launcher: `node scripts/dev.mjs <api|agents|auth|customer-web|downloads> [--lan]`.
// Uses safe local defaults (memory data + payment sandbox + Firebase Auth emulator). Real keys go in .env files.
// --lan: also listen on this computer's Wi-Fi address so a phone on the same Wi-Fi can use a test APK
// (see docs/LOCAL_DEVELOPMENT.md, "Test on your phone"). Set LAN_IP to choose the address yourself.
import { spawn } from "node:child_process";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { lanIp } from "./lan.mjs";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const isWin = process.platform === "win32";
const py = (svc) => join(root, "services", svc, ".venv", isWin ? "Scripts/python.exe" : "bin/python");
const lan = process.argv.includes("--lan");
const ip = lan ? lanIp() : null;

// The Auth emulator reads its listen address from firebase.json; --lan uses a copy that listens on every interface.
function lanFirebaseConfig() {
  const config = JSON.parse(readFileSync(join(root, "firebase/firebase.json"), "utf8"));
  config.emulators.auth.host = "0.0.0.0";
  writeFileSync(join(root, "firebase/firebase.lan.json"), JSON.stringify(config, null, 2));
  return ["--config", "firebase.lan.json"];
}

const shared = {
  ENVIRONMENT: "local",
  FIREBASE_PROJECT_ID: "demo-gudmeal",
  FIREBASE_AUTH_EMULATOR_HOST: process.env.FIREBASE_AUTH_EMULATOR_HOST ?? "127.0.0.1:9099",
  PYTHONUNBUFFERED: "1",
};

const targets = {
  api: {
    cmd: py("api"),
    args: ["-m", "uvicorn", "--factory", "gudmeal_api.main:app_factory", "--port", "8000", ...(lan ? ["--host", "0.0.0.0"] : [])],
    cwd: join(root, "services/api"),
    env: {
      // Local dev creates tables directly (no migrations): bump the file name when the money schema changes.
      DATA_BACKEND: "memory", SEED_DEMO_DATA: "true", DATABASE_URL: "sqlite+aiosqlite:///./gudmeal_local_v3.db",
      // With --lan the payment sandbox page is opened by the phone, so its links use the Wi-Fi address.
      PUBLIC_BASE_URL: `http://${ip ?? "localhost"}:8000`, PAYMENT_CALLBACK_URL: "http://localhost:3000/checkout/callback",
      INTERNAL_SHARED_SECRET: "local-dev-only", CHECK_TOKEN_REVOCATION: "false",
      // Gudy on WhatsApp with the sandbox sender: try it at http://localhost:8000/v1/dev/whatsapp
      WHATSAPP_ENABLED: "true", WHATSAPP_PROVIDER: "sandbox", AGENTS_BASE_URL: "http://localhost:8100",
    },
  },
  agents: {
    cmd: py("agents"),
    args: ["-m", "uvicorn", "--factory", "gudmeal_agents.main:app_factory", "--port", "8100", ...(lan ? ["--host", "0.0.0.0"] : [])],
    cwd: join(root, "services/agents"),
    env: { API_BASE_URL: "http://localhost:8000", CHECKPOINTER: "sqlite" },
  },
  // Serves test APKs (mobile/dist, made by scripts/build-test-apk.mjs) to phones on the same Wi-Fi.
  downloads: {
    cmd: isWin ? "python" : "python3",
    args: ["-m", "http.server", "8090", "--bind", lan ? "0.0.0.0" : "127.0.0.1", "--directory", join(root, "mobile/dist")],
    cwd: root,
    env: {},
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
    args: ["--non-interactive", "emulators:start", "--only", "auth", "--project", "demo-gudmeal", ...(lan ? lanFirebaseConfig() : [])],
    cwd: join(root, "firebase"),
    env: {},
    shell: isWin,
  },
};

const name = process.argv[2];
const target = targets[name];
if (!target) {
  console.error(`usage: node scripts/dev.mjs <${Object.keys(targets).join("|")}> [--lan]`);
  process.exit(2);
}
if (lan) console.log(`LAN mode: phones on this Wi-Fi reach ${name} at http://${ip} (allow it if Windows Firewall asks)`);
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
