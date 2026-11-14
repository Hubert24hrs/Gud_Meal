"""List Gemini models available to GOOGLE_API_KEY and check that GEMINI_MODEL / GEMINI_FALLBACK_MODEL exist.

Run before pinning a model for staging/production (ADR-0011):
    uv run python scripts/check_gemini_models.py
"""

from __future__ import annotations

import os
import sys


def main() -> int:
    key = os.environ.get("GOOGLE_API_KEY")
    if not key:
        print("GOOGLE_API_KEY is not set", file=sys.stderr)
        return 2
    from google import genai

    client = genai.Client(api_key=key)
    names = sorted(m.name.removeprefix("models/") for m in client.models.list())
    flash = [n for n in names if "flash" in n]
    print("Flash models available to this key:")
    for n in flash:
        print("  ", n)
    status = 0
    for var in ("GEMINI_MODEL", "GEMINI_FALLBACK_MODEL"):
        wanted = os.environ.get(var)
        if wanted:
            ok = wanted in names
            print(f"{var}={wanted}: {'OK' if ok else 'NOT AVAILABLE'}")
            status = status or (0 if ok else 1)
    return status


if __name__ == "__main__":
    raise SystemExit(main())
