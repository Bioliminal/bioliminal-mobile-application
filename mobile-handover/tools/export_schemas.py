#!/usr/bin/env python3
"""Regenerate schemas/session.schema.json from the live pydantic models.

Run after any change to software/server/src/auralink/api/schemas.py to keep
the mobile-handover JSON schema in lockstep.

Usage:
    cd software/mobile-handover/tools
    ../../server/.venv/bin/python export_schemas.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
HANDOVER = HERE.parent
SERVER_SRC = HANDOVER.parent / "server" / "src"
SCHEMA_OUT = HANDOVER / "schemas" / "session.schema.json"

sys.path.insert(0, str(SERVER_SRC))
from auralink.api.schemas import Session  # noqa: E402

schema = Session.model_json_schema()
SCHEMA_OUT.parent.mkdir(parents=True, exist_ok=True)
SCHEMA_OUT.write_text(json.dumps(schema, indent=2) + "\n")
print(f"wrote {SCHEMA_OUT.relative_to(HANDOVER.parent)}")
