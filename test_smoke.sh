#!/usr/bin/env bash
# Smoke test: (1) plugin discovery in the provider registry, (2) live streaming round-trip.
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Locate the hermes-agent source tree (for registry import)
if [ -n "${HERMES_REPO:-}" ]; then
  cd "$HERMES_REPO"
elif [ -d "$HERMES_HOME/hermes-agent" ]; then
  cd "$HERMES_HOME/hermes-agent"
else
  echo "NOTE: hermes-agent source not found; skipping registry check (install plugin first)."
  cd "$(dirname "$0")"
fi

if [ -d "providers" ]; then
  python3 - <<'EOF'
from providers import list_providers
names = [p.name for p in list_providers()]
assert "clinepass" in names, f"clinepass not in registry: {names}"
prof = [p for p in list_providers() if p.name == "clinepass"][0]
assert prof.base_url == "https://api.cline.bot/api/v1"
assert "CLINE_API_KEY" in prof.env_vars
assert len(prof.fallback_models) == 11
print("[OK] registry discovery: clinepass registered, 11 fallback models")
EOF
else
  echo "[SKIP] registry check (no providers/ package in cwd)"
fi

# Live streaming round-trip (only if key present)
if grep -q '^CLINE_API_KEY=' "$HERMES_HOME/.env" 2>/dev/null; then
  set -a; . "$HERMES_HOME/.env"; set +a
  resp="$(curl -sS -m 60 https://api.cline.bot/api/v1/chat/completions \
    -H "Authorization: Bearer $CLINE_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"model":"cline-pass/glm-5.2","messages":[{"role":"user","content":"Reply with exactly: OK"}],"max_tokens":500,"stream":true}' || true)"
  if echo "$resp" | head -3 | grep -q "chat.completion.chunk"; then
    echo "[OK] live streaming round-trip"
  else
    echo "[ERR] streaming response unexpected:" && echo "$resp" | head -5 && exit 1
  fi
else
  echo "[SKIP] live round-trip (no CLINE_API_KEY in $HERMES_HOME/.env)"
fi

echo "Smoke test passed."
