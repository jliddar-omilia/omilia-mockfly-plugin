#!/bin/bash
# Verifies the demo-data-generator "full path" import procedure documented
# in plugins/mockfly/skills/mockfly-projects/SKILL.md actually works against
# the real Mockfly API. Creates one throwaway project, tests seed-data
# rules, magic values, last-match-wins ordering, and X-API-Key enforcement,
# then deletes the project. Prints only status codes and bodies — never
# your API key.
#
# Requires MOCKFLY_ACCOUNT_API_KEY to be set in this shell.
# Usage: bash scripts/verify-mockfly-import.sh

set -euo pipefail

if [ -z "${MOCKFLY_ACCOUNT_API_KEY:-}" ]; then
  echo "MOCKFLY_ACCOUNT_API_KEY is not set in this shell. Export it first, then re-run this script." >&2
  exit 1
fi

PASS=0
FAIL=0

check() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "PASS  $desc (got $actual)"
    PASS=$((PASS+1))
  else
    echo "FAIL  $desc (expected $expected, got $actual)"
    FAIL=$((FAIL+1))
  fi
}

echo "== 1. Building the import payload =="
PAYLOAD_FILE=$(mktemp)
python3 - "$PAYLOAD_FILE" <<'PYEOF'
import json, sys, time

group = f"mockfly-plugin-verify-{int(time.time())}"
api_key_value = f"demo-api-key-{group}"

auth_check = {
    "operator": "or",
    "conditions": [
        {"source": "header", "property": "X-API-Key", "comparator": "notExists"},
        {"source": "header", "property": "X-API-Key", "comparator": "distinct", "value": api_key_value},
    ],
}

endpoint = {
    "path": "/api/v1/billing/get_account_information",
    "method": "GET",
    "responses": [
        {"name": "default-not-found", "status": 404, "body": {"status": "error", "message": "Account not found"}, "rules": []},
        {"name": "seed-AC001", "status": 200, "body": {"status": "success", "data": {"account_number": "AC001", "customer_name": "Test User One", "balance": 100}},
         "rules": [{"source": "queryString", "property": "account_number", "comparator": "equal", "value": "AC001"}]},
        {"name": "seed-AC002", "status": 200, "body": {"status": "success", "data": {"account_number": "AC002", "customer_name": "Test User Two", "balance": 200}},
         "rules": [{"source": "queryString", "property": "account_number", "comparator": "equal", "value": "AC002"}]},
        {"name": "magic-ERROR-TEST", "status": 500, "body": {"status": "error", "message": "Internal server error"},
         "rules": [{"source": "queryString", "property": "account_number", "comparator": "equal", "value": "ERROR-TEST"}]},
        {"name": "auth-check", "status": 401, "body": {"detail": "Invalid API key"}, "rules": [auth_check]},
    ],
}

payload = {"project": {"name": group}, "endpoints": [endpoint]}

with open(sys.argv[1], "w") as f:
    json.dump(payload, f)

# Stash values the shell script needs, in a second file next to the payload
with open(sys.argv[1] + ".meta", "w") as f:
    json.dump({"group": group, "api_key_value": api_key_value}, f)
PYEOF

GROUP=$(python3 -c "import json; print(json.load(open('$PAYLOAD_FILE.meta'))['group'])")
API_KEY_VALUE=$(python3 -c "import json; print(json.load(open('$PAYLOAD_FILE.meta'))['api_key_value'])")
echo "Test project name: $GROUP"

echo
echo "== 2. Importing (POST /public/projects/import, account key) =="
IMPORT_RESPONSE=$(curl -s -X POST https://api.mockfly.dev/public/projects/import \
  -H "Authorization: $MOCKFLY_ACCOUNT_API_KEY" \
  -H "Content-Type: application/json" \
  -d @"$PAYLOAD_FILE")

echo "$IMPORT_RESPONSE" | python3 -m json.tool 2>/dev/null | grep -v privateApiKey || echo "(response was not JSON — this is the actual failure to look at)"

SLUG=$(echo "$IMPORT_RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin).get('slug',''))" 2>/dev/null || echo "")
PROJECT_ID=$(echo "$IMPORT_RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin).get('_id',''))" 2>/dev/null || echo "")
PROJECT_KEY=$(echo "$IMPORT_RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin).get('privateApiKey',''))" 2>/dev/null || echo "")

if [ -z "$SLUG" ] || [ -z "$PROJECT_ID" ]; then
  echo "FAIL  import call did not return a usable project (slug/_id missing) — stopping here"
  rm -f "$PAYLOAD_FILE" "$PAYLOAD_FILE.meta"
  exit 1
fi

MOCK_URL="https://api.mockfly.dev/mocks/${SLUG}"
echo "Mock base URL: $MOCK_URL"
echo "PASS  import returned a slug and project id"
PASS=$((PASS+1))

echo
echo "== 3. Testing behavior against the live mock =="

# curl -s -o /dev/null -w on a network-level failure (DNS not yet
# propagated, connection refused, TLS not ready) exits non-zero, and
# under `set -e` that kills the whole script with no explanation. Never
# let a single curl call do that: capture stderr, print it on failure,
# and return the "000" sentinel instead of aborting.
curl_code() {
  local url="$1"; shift
  local err
  local code
  if ! code=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 10 "$url" "$@" 2>/tmp/verify-mockfly-curl-err.$$); then
    err=$(cat /tmp/verify-mockfly-curl-err.$$)
    rm -f /tmp/verify-mockfly-curl-err.$$
    echo "  (curl failed at the network level: $err)" >&2
    echo "000"
    return
  fi
  rm -f /tmp/verify-mockfly-curl-err.$$
  echo "$code"
}

ENDPOINT="$MOCK_URL/api/v1/billing/get_account_information"

echo "Waiting for $MOCK_URL to become reachable..."
READY=0
for i in $(seq 1 15); do
  code=$(curl_code "$ENDPOINT?account_number=AC001" -H "X-API-Key: $API_KEY_VALUE")
  if [ "$code" != "000" ]; then
    READY=1
    break
  fi
  echo "  not reachable yet (attempt $i/15), waiting 3s..."
  sleep 3
done

if [ "$READY" -eq 0 ]; then
  echo "FAIL  mock never became reachable after 45s — see curl errors above"
  FAIL=$((FAIL+1))
else
  check "AC001 with correct key -> 200" "200" "$code"

  code_ac002=$(curl_code "$ENDPOINT?account_number=AC002" -H "X-API-Key: $API_KEY_VALUE")
  check "AC002 with correct key -> 200" "200" "$code_ac002"

  code_error=$(curl_code "$ENDPOINT?account_number=ERROR-TEST" -H "X-API-Key: $API_KEY_VALUE")
  check "ERROR-TEST with correct key -> 500" "500" "$code_error"

  code_unknown=$(curl_code "$ENDPOINT?account_number=NOBODY" -H "X-API-Key: $API_KEY_VALUE")
  check "unknown identifier -> 404 (default)" "404" "$code_unknown"

  code_no_header=$(curl_code "$ENDPOINT?account_number=AC001")
  check "AC001, no X-API-Key -> 401 (auth overrides seed match)" "401" "$code_no_header"

  code_wrong_header=$(curl_code "$ENDPOINT?account_number=AC001" -H "X-API-Key: wrong-value")
  check "AC001, wrong X-API-Key -> 401 (distinct comparator works)" "401" "$code_wrong_header"
fi

echo
echo "== 4. Cleaning up test project =="
DELETE_CODE=$(curl_code "https://api.mockfly.dev/public/projects/$PROJECT_ID" \
  -X DELETE -H "Authorization: $MOCKFLY_ACCOUNT_API_KEY")
check "test project deleted -> 200" "200" "$DELETE_CODE"

rm -f "$PAYLOAD_FILE" "$PAYLOAD_FILE.meta"

echo
echo "== Summary: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
