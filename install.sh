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

install_to "$HERMES_HOME"

if [ -d "$HERMES_HOME/profiles" ]; then
  for profile_dir in "$HERMES_HOME"/profiles/*/; do
    [ -d "$profile_dir" ] || continue
    install_to "$profile_dir"
  done
fi

echo ""
echo "Done. Now set your API key (app.cline.bot -> Settings -> API Keys):"
echo "  echo 'CLINE_API_KEY=sk_...' >> $HERMES_HOME/.env"
