"""Phone tests: a test app recognises this API on the Wi-Fi by its health answer."""

from __future__ import annotations

import httpx


async def test_health_names_the_service(client: httpx.AsyncClient) -> None:
    r = await client.get("/v1/health")
    assert r.status_code == 200
    # mobile/core/lib/src/test_server.dart looks for exactly this name.
    assert r.json() == {"status": "ok", "service": "gudmeal-api"}
