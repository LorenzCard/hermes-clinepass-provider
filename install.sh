#!/usr/bin/env bash
# Install the clinepass model-provider plugin into Hermes (default home + all profiles).
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/clinepass"

if [ ! -d "$SRC" ]; then
  echo "ERROR: plugin source not found at $SRC" >&2
  exit 1
fi

install_to() {
  local dest="$1/plugins/model-providers/clinepass"
  mkdir -p "$dest"
  cp "$SRC/__init__.py" "$SRC/plugin.yaml" "$dest/"
  echo "installed: $dest"
}

# Add the providers.clinepass config block (required for /model switcher,
# 'hermes model' and the dashboard — see README "IMPORTANT" section).
add_provider_config() {
  local cfg="$1/config.yaml"
  [ -f "$cfg" ] || { echo "no config.yaml: $cfg"; return 0; }
  if grep -q "^providers:" "$cfg" && grep -A3 "^providers:" "$cfg" | grep -q "clinepass"; then
    echo "config already has providers.clinepass: $cfg"
    return 0
  fi
  # NOTE: naive append — if you already have a `providers:` section, add the
  # clinepass entry under it manually instead of running this.
  cat >> "$cfg" <<'EOF'
providers:
  clinepass:
    name: ClinePass
    api: https://api.cline.bot/api/v1
    key_env: CLINE_API_KEY
    transport: openai_chat
EOF
  echo "config updated: $cfg"
}

install_to "$HERMES_HOME"
add_provider_config "$HERMES_HOME"

if [ -d "$HERMES_HOME/profiles" ]; then
  for profile_dir in "$HERMES_HOME"/profiles/*/; do
    [ -d "$profile_dir" ] || continue
    install_to "$profile_dir"
    add_provider_config "$profile_dir"
  done
fi

echo ""
echo "Done. Now set your API key (app.cline.bot -> Settings -> API Keys):"
echo "  echo 'CLINE_API_KEY=sk_...' >> $HERMES_HOME/.env"
echo "Then restart Hermes processes (dashboard/gateway) so they reload the registry."
