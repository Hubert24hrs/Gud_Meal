import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { assertFails, assertSucceeds, initializeTestEnvironment, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { ref, uploadBytes, getBytes } from "firebase/storage";
import { afterAll, beforeAll, describe, it } from "vitest";

let env: RulesTestEnvironment;
const PNG = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-gudmeal-rules",
    storage: { rules: readFileSync(resolve(__dirname, "../storage.rules"), "utf8") },
  });
});
afterAll(async () => env.cleanup());

const owner = () =>
  env.authenticatedContext("owner-1", { roles: ["restaurant_owner"], restaurant_roles: { "r-jj": "owner" } }).storage();
const customer = (uid = "cust-1") => env.authenticatedContext(uid, { roles: [] }).storage();

describe("storage", () => {
  it("restaurant managers upload images for their own restaurant only", async () => {
    await assertSucceeds(uploadBytes(ref(owner(), "public/restaurants/r-jj/logo.png"), PNG, { contentType: "image/png" }));
    await assertFails(uploadBytes(ref(owner(), "public/restaurants/r-other/logo.png"), PNG, { contentType: "image/png" }));
    await assertFails(uploadBytes(ref(owner(), "public/restaurants/r-jj/x.html"), PNG, { contentType: "text/html" }));
  });
  it("onboarding documents are private to the applicant", async () => {
    await assertSucceeds(uploadBytes(ref(customer(), "applications/cust-1/cac.pdf"), PNG, { contentType: "application/pdf" }));
    await assertFails(uploadBytes(ref(customer(), "applications/cust-2/cac.pdf"), PNG, { contentType: "application/pdf" }));
    await assertFails(getBytes(ref(customer("cust-2"), "applications/cust-1/cac.pdf")));
  });
  it("everything else is denied", async () => {
    await assertFails(uploadBytes(ref(customer(), "random/file.png"), PNG, { contentType: "image/png" }));
  });
});
