#!/usr/bin/env bash
# Smoke-test: POST the sample fixture to a running auralink server.
#
# Usage:
#   ./post_sample.sh                       # defaults to http://localhost:8000
#   ./post_sample.sh http://my-server:8000
#
# A successful run prints a JSON body like:
#   {"session_id":"...","frames_received":5}
#
# Anything else (404, 422, connection refused) means either the server is
# down or the fixture has drifted from the schema. If the server is up and
# the fixture is rejected, regenerate via tools/export_schemas.py and
# rebuild the fixture from the latest pydantic models.
set -euo pipefail

BASE="${1:-http://localhost:8000}"
HERE="$(cd "$(dirname "$0")" && pwd)"
FIXTURE="$HERE/../fixtures/sample_valid_session.json"

if [[ ! -f "$FIXTURE" ]]; then
  echo "fixture not found: $FIXTURE" >&2
  exit 2
fi

echo "POST $BASE/sessions  (fixture: $(basename "$FIXTURE"))"
curl -sS -X POST \
  -H 'content-type: application/json' \
  --data-binary "@$FIXTURE" \
  "$BASE/sessions"
echo
