/**
 * Firestore security rules tests. Run inside the emulator:
 *   npx firebase emulators:exec --only firestore,storage --project demo-gudmeal-rules "npm run test:rules -w firebase"
 */
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, updateDoc, collection, query, where, getDocs, serverTimestamp, deleteDoc } from "firebase/firestore";
import { afterAll, beforeAll, beforeEach, describe, it } from "vitest";

let env: RulesTestEnvironment;

const ORDER = {
  id: "o1", customer_id: "cust-1", restaurant_id: "r-jj", rider_id: "rider-1", status: "in_transit",
  breakdown: { total_kobo: 945000 },
};

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-gudmeal-rules",
    firestore: { rules: readFileSync(resolve(__dirname, "../firestore.rules"), "utf8") },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "restaurant_profiles/r-jj"), { id: "r-jj", status: "active", name: "Jollof Junction" });
    await setDoc(doc(db, "restaurant_profiles/r-new"), { id: "r-new", status: "pending", name: "New Place" });
    await setDoc(doc(db, "food_items/i1"), { id: "i1", restaurant_id: "r-jj", price_kobo: 550000 });
    await setDoc(doc(db, "orders/o1"), ORDER);
    await setDoc(doc(db, "orders/o1/customer_private/codes"), { delivery_code: "1234", pickup_code: "5678" });
    await setDoc(doc(db, "order_events/e1"), { order_id: "o1", to_status: "paid" });
    await setDoc(doc(db, "rider_profiles/rider-1"), { uid: "rider-1", last_location: { lat: 6.4, lng: 3.4 } });
    await setDoc(doc(db, "delivery_tracking/o1"), { order_id: "o1", customer_id: "cust-1" });
    await setDoc(doc(db, "notifications/n1"), { recipient_uid: "cust-1", title: "Hi", read_at: null });
    await setDoc(doc(db, "vouchers/WELCOME500"), { code: "WELCOME500" });
    await setDoc(doc(db, "customer_profiles/cust-1"), { uid: "cust-1", allergens: ["peanuts"] });
  });
});

const anon = () => env.unauthenticatedContext().firestore();
const customer = (uid = "cust-1") => env.authenticatedContext(uid, { roles: [] }).firestore();
const restaurantStaff = (rid = "r-jj") =>
  env.authenticatedContext("staff-1", { roles: ["restaurant_staff"], restaurant_roles: { [rid]: "staff" } }).firestore();
const rider = (uid = "rider-1") => env.authenticatedContext(uid, { roles: ["rider"] }).firestore();
const support = () => env.authenticatedContext("support-1", { roles: ["support_agent"] }).firestore();

describe("catalog", () => {
  it("anyone can read active restaurants and menu items", async () => {
    await assertSucceeds(getDoc(doc(anon(), "restaurant_profiles/r-jj")));
    await assertSucceeds(getDoc(doc(anon(), "food_items/i1")));
  });
  it("pending restaurants are hidden from the public", async () => {
    await assertFails(getDoc(doc(anon(), "restaurant_profiles/r-new")));
  });
  it("nobody writes the catalog from a client", async () => {
    await assertFails(setDoc(doc(restaurantStaff(), "food_items/i1"), { price_kobo: 1 }));
    await assertFails(setDoc(doc(customer(), "restaurant_profiles/r-jj"), { status: "active" }));
  });
});

describe("orders", () => {
  it("the customer, the restaurant, the assigned rider and staff can read", async () => {
    await assertSucceeds(getDoc(doc(customer(), "orders/o1")));
    await assertSucceeds(getDoc(doc(restaurantStaff(), "orders/o1")));
    await assertSucceeds(getDoc(doc(rider(), "orders/o1")));
    await assertSucceeds(getDoc(doc(support(), "orders/o1")));
  });
  it("other customers, restaurants and riders cannot", async () => {
    await assertFails(getDoc(doc(customer("cust-2"), "orders/o1")));
    await assertFails(getDoc(doc(restaurantStaff("r-other"), "orders/o1")));
    await assertFails(getDoc(doc(rider("rider-2"), "orders/o1")));
    await assertFails(getDoc(doc(anon(), "orders/o1")));
  });
  it("no client can change an order (status is API-only)", async () => {
    await assertFails(updateDoc(doc(customer(), "orders/o1"), { status: "delivered" }));
    await assertFails(updateDoc(doc(restaurantStaff(), "orders/o1"), { status: "restaurant_accepted" }));
    await assertFails(updateDoc(doc(rider(), "orders/o1"), { status: "delivered" }));
    await assertFails(updateDoc(doc(support(), "orders/o1"), { status: "refunded" }));
    await assertFails(setDoc(doc(customer(), "orders/o2"), { ...ORDER, id: "o2", status: "paid" }));
  });
  it("list queries are scoped by ownership", async () => {
    await assertSucceeds(getDocs(query(collection(customer(), "orders"), where("customer_id", "==", "cust-1"))));
    await assertFails(getDocs(collection(customer(), "orders")));
    await assertSucceeds(getDocs(query(collection(restaurantStaff(), "orders"), where("restaurant_id", "==", "r-jj"))));
    await assertFails(getDocs(query(collection(restaurantStaff(), "orders"), where("restaurant_id", "==", "r-zz"))));
  });
  it("delivery codes are visible to the customer only", async () => {
    await assertSucceeds(getDoc(doc(customer(), "orders/o1/customer_private/codes")));
    await assertFails(getDoc(doc(rider(), "orders/o1/customer_private/codes")));
    await assertFails(getDoc(doc(restaurantStaff(), "orders/o1/customer_private/codes")));
  });
  it("order events follow order visibility", async () => {
    await assertSucceeds(getDoc(doc(customer(), "order_events/e1")));
    await assertFails(getDoc(doc(customer("cust-2"), "order_events/e1")));
  });
});

describe("carts", () => {
  it("owners can write a valid cart", async () => {
    await assertSucceeds(setDoc(doc(customer(), "carts/cust-1"), {
      restaurant_id: "r-jj", lines: [{ item_id: "i1", quantity: 2 }], updated_at: serverTimestamp(),
    }));
    await assertSucceeds(deleteDoc(doc(customer(), "carts/cust-1")));
  });
  it("carts cannot carry prices or extra fields, or be written for others", async () => {
    await assertFails(setDoc(doc(customer(), "carts/cust-1"), {
      restaurant_id: "r-jj", lines: [], updated_at: serverTimestamp(), total_kobo: 1,
    }));
    await assertFails(setDoc(doc(customer("cust-2"), "carts/cust-1"), {
      restaurant_id: "r-jj", lines: [], updated_at: serverTimestamp(),
    }));
  });
});

describe("people, delivery and engagement", () => {
  it("rider location is private to the rider and staff", async () => {
    await assertSucceeds(getDoc(doc(rider(), "rider_profiles/rider-1")));
    await assertSucceeds(getDoc(doc(support(), "rider_profiles/rider-1")));
    await assertFails(getDoc(doc(customer(), "rider_profiles/rider-1")));
  });
  it("tracking is visible to the order's customer", async () => {
    await assertSucceeds(getDoc(doc(customer(), "delivery_tracking/o1")));
    await assertFails(getDoc(doc(customer("cust-2"), "delivery_tracking/o1")));
  });
  it("profiles are private", async () => {
    await assertSucceeds(getDoc(doc(customer(), "customer_profiles/cust-1")));
    await assertFails(getDoc(doc(customer("cust-2"), "customer_profiles/cust-1")));
  });
  it("recipients may only mark notifications as read", async () => {
    await assertSucceeds(updateDoc(doc(customer(), "notifications/n1"), { read_at: serverTimestamp() }));
    await assertFails(updateDoc(doc(customer(), "notifications/n1"), { title: "changed" }));
    await assertFails(updateDoc(doc(customer("cust-2"), "notifications/n1"), { read_at: serverTimestamp() }));
  });
  it("vouchers are not readable by customers", async () => {
    await assertFails(getDoc(doc(customer(), "vouchers/WELCOME500")));
    await assertSucceeds(getDoc(doc(support(), "vouchers/WELCOME500")));
  });
  it("unknown collections are denied", async () => {
    await assertFails(getDoc(doc(support(), "secrets/x")));
    await assertFails(setDoc(doc(customer(), "anything/x"), { a: 1 }));
  });
});
