# ADR-0020: Phone test apps find the test server by themselves

- **Status:** Accepted (built and tested without a phone; not yet run on one)
- **Date:** 2026-11-17
- **Context owner:** owner's approval of 2026-11-17: make the test apps find this computer by themselves on any
  Wi-Fi

## Context

The owner tests alone: both apps on one Android phone, the whole stack on one Windows laptop, over Wi-Fi. A test
APK had the laptop's address built in. The laptop has one Wi-Fi adapter and joins whichever saved network is in
reach, so its address changed three times on 2026-11-17 (192.168.100.8, then 10.221.34.228, then back). Each
change left both installed apps unable to connect until both were rebuilt (about seven minutes each) and
installed again, and the payment sandbox page kept pointing at the address the API had been started with.

## Decision

1. **The app looks for the server when it starts** (phone test builds only). It tries, in this order: the address
   that worked last time (kept in the app's cache folder), the address the build was made for, and the addresses
   of earlier builds (`TEST_SERVER_HOSTS`; `scripts/build-test-apk.mjs` remembers them in
   `mobile/dist/test-server-hosts.json`). When none answers it searches: every address from 1 to 254 on the
   networks of the phone's own Wi-Fi-like interfaces, then on the networks of the known addresses. At most four
   networks, private ranges only (10.x, 172.16-31.x, 192.168.x). Each address gets a connection attempt on port
   8000 (450 ms); one that accepts is asked `GET /v1/health`, which must answer `"service": "gudmeal-api"`.
2. **Before anything connects.** Firebase's sign-in emulator can be given an address only once per run, so the
   search runs in `main()` before Firebase starts. When nothing answers, a small screen says what to do, tries
   again, takes a typed address, or opens the app anyway.
3. **While the app is open.** When the app comes back to the front and the server does not answer three times
   running, a notice offers to look again. A server found at a new address needs the app closed and opened again;
   the notice has the button.
4. **The server follows too.** With `SANDBOX_FOLLOWS_LAN_ADDRESS=true` (set by `dev.mjs --lan`) the payment
   sandbox link is built for the device that pays (`gudmeal_api/lan.py`): the address the phone reached the API
   at; for a request through `localhost` (Yummy, the assistant, or a website on this computer), the address a
   phone last reached the API at; before any phone, the computer's guess of its Wi-Fi address (a 192.168.x.x
   address first); `PUBLIC_BASE_URL` last. In LAN mode every service already listens on every interface, so
   nothing needs a restart.
   *Fixed 2026-11-19:* the link used to be the computer's guess only. With a VPN connected (Proton VPN on the
   owner's laptop) that guess is the VPN's tunnel address, 10.2.0.2, and "Pay by card, transfer or USSD" opened
   a page the phone could never load.
5. **Never in a store build.** `AppConfig.findTestServer` is true only with `FIND_TEST_SERVER=true` and the
   Firebase emulators on, and never in a browser. Only `scripts/build-test-apk.mjs` sets it. The payment sandbox
   exists only when `ENVIRONMENT` is local or test.

## Alternatives considered

- **Rebuild on every change** (what we did): fifteen minutes and a reinstall each time, and the apps fail without
  saying why.
- **A fixed name instead of an address** (`computer.local`): depends on Windows answering name lookups on a network
  it marks Public and on the phone's resolver. It could not be tested without the phone.
- **A public tunnel:** needs an outside service and the internet, and puts a test server with demo accounts on the
  internet.
- **The address from each request's `Host` header** for the payment link: right for the app, wrong for Yummy, which
  calls the API from the same computer and hands the link to the phone.
- **A discovery service** (the server announces itself): two new dependencies, and the multicast it needs is often
  blocked on hotspots.

## Consequences

- A test build keeps working when the computer changes Wi-Fi: put the phone on the same Wi-Fi and open the app.
- The search knocks on port 8000 of up to about a thousand addresses of the local network. It happens only in test
  builds, and only when the known addresses do not answer.
- The health answer identifies the server; it does not prove who runs it. Anyone on the same Wi-Fi could answer as
  the test server and receive demo-account sign-ins. Test builds carry only demo accounts and sandbox payments and
  are for networks you trust (LOCAL_DEVELOPMENT.md, section 6).
- A network with more than 254 addresses is searched only around the phone's own address and the known ones; the
  typed address covers the rest.
- `GET /v1/health` now also returns `"service": "gudmeal-api"`.
- The download page and its QR code still carry the address the computer had when they were made. That matters
  only for installing.

## Tests

- App: `mobile/core/test/test_server_test.dart` (the order of the search, private networks only, a typed address,
  both screens) and `test_server_connection_test.dart` (real connections against small servers on the test
  machine).
- API: `tests/unit/test_phone_test_address.py` (including a VPN), `tests/integration/test_phone_test_server.py`,
  `tests/integration/test_phone_payment_address.py` (a phone pays at the address it reached the API at).
- Live stack: `GUDMEAL_LIVE_SEARCH_AS=<an address on this Wi-Fi> flutter test test/test_server_live_test.dart` in
  `mobile/core` searches the real Wi-Fi from this computer the way a phone would.
- Not run on a phone yet.
