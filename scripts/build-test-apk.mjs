#!/usr/bin/env node
// Builds Android test APKs of the customer and rider apps that talk to the local stack on THIS computer over Wi-Fi,
// and puts them in mobile/dist with a download page. Then: `node scripts/dev.mjs downloads --lan` and open
// http://<this computer's Wi-Fi address>:8090 on the phone (see docs/LOCAL_DEVELOPMENT.md, "Test on your phone").
// These builds use the Firebase Auth emulator and the payment sandbox: they are for testing, never for the store.
//   node scripts/build-test-apk.mjs                  # both apps, for every Android phone
//   node scripts/build-test-apk.mjs rider --arm64    # one app, 64-bit phones only (smaller; needs less disk to build)
//   node scripts/build-test-apk.mjs --page           # only rewrite the download page for the APKs already built
import { spawnSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, rmSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { lanIp } from "./lan.mjs";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const ip = lanIp();
const args = process.argv.slice(2);
const wanted = args.filter((a) => !a.startsWith("-"));
const arm64 = args.includes("--arm64");
const pageOnly = args.includes("--page");
const apps = [
  { id: "customer", file: "gudmeal-customer.apk", title: "Gud Meal", note: "Order food, beauty products and send packages" },
  { id: "rider", file: "gudmeal-rider.apk", title: "Gud Meal Rider", note: "Accept deliveries and confirm them with the customer's code" },
];

const dist = join(root, "mobile/dist");
mkdirSync(dist, { recursive: true });
for (const app of pageOnly ? [] : apps.filter((a) => wanted.length === 0 || wanted.includes(a.id))) {
  console.log(`\n== Building ${app.title} for http://${ip} ...`);
  const result = spawnSync(
    "flutter",
    [
      "build", "apk", "--release",
      `--dart-define=API_URL=http://${ip}:8000`,
      `--dart-define=AGENTS_URL=http://${ip}:8100`,
      `--dart-define=AUTH_EMULATOR_HOST=${ip}`,
      "--dart-define=USE_FIREBASE_EMULATORS=true",
      ...(arm64 ? ["--target-platform", "android-arm64"] : []),
    ],
    // Plain http to this computer is allowed only in these test builds (see android/app/build.gradle.kts).
    { cwd: join(root, "mobile", app.id), stdio: "inherit", shell: process.platform === "win32",
      env: { ...process.env, GUDMEAL_ALLOW_CLEARTEXT: "true" } },
  );
  if (result.status !== 0) process.exit(result.status ?? 1);
  copyFileSync(join(root, "mobile", app.id, "build/app/outputs/flutter-apk/app-release.apk"), join(dist, app.file));
  // The Android build leaves ~0.5-1 GB of intermediates; they are rebuilt next time, so free the disk now.
  rmSync(join(root, "mobile", app.id, "build/app"), { recursive: true, force: true });
}

for (const app of apps) {
  const apk = join(dist, app.file);
  if (existsSync(apk)) app.size = `${(statSync(apk).size / 1024 / 1024).toFixed(0)} MB`;
}
const ready = apps.filter((a) => a.size);
const built = new Date().toLocaleString("en-GB", { dateStyle: "medium", timeStyle: "short" });
writeFileSync(join(dist, "index.html"), `<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Gud Meal test apps</title>
<style>body{font-family:system-ui,sans-serif;background:#FFF9F3;color:#202521;margin:0;padding:24px}
main{max-width:440px;margin:0 auto}h1{font-size:26px}a.app{display:block;background:#E85D32;color:#fff;text-decoration:none;
border-radius:14px;padding:18px 20px;margin:14px 0;font-weight:700;font-size:18px}a.app small{display:block;font-weight:400;
font-size:14px;opacity:.9;margin-top:4px}ol{padding-left:20px;line-height:1.6}.note{font-size:13px;color:#5f6661}</style>
</head><body><main><h1>Gud Meal test apps</h1>
${ready.map((a) => `<a class="app" href="${a.file}" download>${a.title} (${a.size})<small>${a.note}</small></a>`).join("\n")}
<ol><li>Tap an app to download it, then open the download.</li>
<li>If Android asks, allow your browser to <b>install unknown apps</b>, then tap <b>Install</b>.</li>
<li>Keep this phone on the same Wi-Fi as the computer running Gud Meal.</li></ol>
<p class="note">Test builds made ${built} for the server at ${ip}. They use test accounts and a payment sandbox: no real money moves.</p>
</main></body></html>`);
console.log(`\nReady: ${ready.map((a) => a.file).join(", ") || "no APKs yet"} in mobile/dist.`);
console.log(`Serve them with: node scripts/dev.mjs downloads --lan   ->   http://${ip}:8090`);
