"""This computer's current address on the local network.

Only the local phone test uses it. A phone on the same Wi-Fi opens the payment sandbox page on this computer,
and the computer's address changes with the Wi-Fi it joins, so the address is looked up when it is needed
instead of once at startup (docs/adr/0020-test-apps-find-the-test-server.md).
"""

from __future__ import annotations

import ipaddress
import os
import socket


def current_lan_address() -> str | None:
    """The IPv4 address that devices on the same network reach this computer at, or None when it has none.

    `LAN_IP` overrides the guess, as in scripts/lan.mjs.
    """
    override = os.environ.get("LAN_IP", "").strip()
    if override:
        return override
    probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Connecting a UDP socket sends nothing. It only asks the system which of its own addresses it would use
        # to reach another network, and that is the address of the Wi-Fi (or cable) it is on. 192.0.2.1 is a
        # documentation address that no real host has.
        probe.connect(("192.0.2.1", 9))
        address = str(probe.getsockname()[0])
    except OSError:
        return None  # no network at all
    finally:
        probe.close()
    found = ipaddress.ip_address(address)
    return None if found.is_loopback or found.is_unspecified else address
