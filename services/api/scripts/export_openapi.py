"""Write the OpenAPI document used to generate the TypeScript client (packages/api-client)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

from gudmeal_api.config import Settings
from gudmeal_api.main import create_app

out = Path(sys.argv[1] if len(sys.argv) > 1 else "openapi.json")
spec = create_app(Settings(environment="test")).openapi()
out.write_text(json.dumps(spec, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote {out} ({len(spec['paths'])} paths)")
