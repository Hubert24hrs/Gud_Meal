"""Where a device on this computer's Wi-Fi can reach this API: the address the phone test uses.

Only the local phone test uses it. A phone on the same Wi-Fi opens the payment sandbox page on this computer,
and the computer's address changes with the Wi-Fi it joins, so the address is looked up when it is needed
instead of once at startup (docs/adr/0020-test-apps-find-the-test-server.md).

The best answer is the address the phone itself used to reach this API: whatever the phone reached once, it can
reach again. Guessing this computer's address is the last resort, and a VPN makes the guess go wrong: while one is
connected, asking the system which address it would use for the internet gives the VPN's tunnel address
(10.2.0.2 with Proton VPN), which no phone can reach.
"""

from __future__ import annotations

import ipaddress
import os
import socket
from contextvars import ContextVar, Token
from urllib.parse import urlsplit

#: The address (scheme://host:port) the current request reached this API at; set by the API's middleware.
_request_base: ContextVar[str | None] = ContextVar("lan_request_base", default=None)
#: The last address a device on the network (the test phone) reached this API at.
_last_network_base: str | None = None


def _on_the_network(host: str) -> bool:
    """True for an address another device can use: not loopback, not "any", not link-local."""
    if not host or host.lower() == "localhost":
        return False
    try:
        ip = ipaddress.ip_address(host.strip("[]"))
    except ValueError:
        return True  # a name (like mypc.local) that the device resolved by itself
    return not (ip.is_loopback or ip.is_unspecified or ip.is_link_local)


def remember_request(base_url: str) -> Token[str | None]:
    """Called by the API for every request: the address the client used to reach it (`request.base_url`)."""
    global _last_network_base
    base = base_url.rstrip("/")
    if _on_the_network(urlsplit(base).hostname or ""):
        _last_network_base = base
    return _request_base.set(base)


def forget_request(token: Token[str | None]) -> None:
    _request_base.reset(token)


def forget_devices() -> None:
    """Forget the last device's address (tests; a new phone test starts fresh anyway)."""
    global _last_network_base
    _last_network_base = None


def reachable_base_url(port: int, fallback: str) -> str:
    """Where a device on the Wi-Fi can open a page served by this API, best answer first:

    1. the address the current request came in on, when it is a network address (the phone is asking);
    2. the address a device last reached this API at (Yummy, the assistant, or a website on this computer asks
       for the phone, through `localhost`);
    3. this computer's guess of its own Wi-Fi address;
    4. `fallback` (PUBLIC_BASE_URL, the address the server was started with).
    """
    current = _request_base.get()
    if current and _on_the_network(urlsplit(current).hostname or ""):
        return current
    if _last_network_base:
        return _last_network_base
    address = current_lan_address()
    return f"http://{address}:{port}" if address else fallback


def current_lan_address() -> str | None:
    """This computer's IPv4 address on its Wi-Fi (or cable), or None when it has none.

    `LAN_IP` overrides the guess, as in scripts/lan.mjs. A 192.168.x.x address wins over the address the system
    would use for the internet, because that one is a VPN's tunnel while a VPN is connected; home and office
    Wi-Fi is almost always 192.168.x.x (scripts/lan.mjs prefers it too).
    """
    override = os.environ.get("LAN_IP", "").strip()
    if override:
        return override
    candidates = [a for a in (_routed_address(), *_host_addresses()) if a and _on_the_network(a)]
    for address in candidates:
        if address.startswith("192.168."):
            return address
    return candidates[0] if candidates else None


def _routed_address() -> str | None:
    """The address the system would use to reach another network (None without a network)."""
    probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Connecting a UDP socket sends nothing. It only asks the system which of its own addresses it would use
        # to reach another network. 192.0.2.1 is a documentation address that no real host has.
        probe.connect(("192.0.2.1", 9))
        return str(probe.getsockname()[0])
    except OSError:
        return None  # no network at all
    finally:
        probe.close()


def _host_addresses() -> list[str]:
    """Every IPv4 address of this computer (Wi-Fi, cable, VPN, virtual switches), in no particular order."""
    try:
        infos = socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET)
    except OSError:
        return []
    return list(dict.fromkeys(str(info[4][0]) for info in infos))
