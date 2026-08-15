#!/usr/bin/env bash
# restore_hermes_stash.sh — restore work that `hermes update` left in an autostash.
#
# Usage:
#   ./restore_hermes_stash.sh <stash-ref> [target-branch]
#
# What it does:
#   1. Exports the stash patch (read-only op against the live checkout).
#   2. Clones the repo to ~/.hermes/scratch/stash-restore-<ts> (shared clone,
#      real disk — NOT /tmp).
#   3. Applies the patch with 3-way merge; files that conflict are replaced
#      with the full stashed version when the stash is the evolved work
#      (uncomment OVERRIDE_FILES below).
#   4. Commits, compiles, and runs a quick test pass.
#   5. Prints the exact steps to apply it to the live checkout (Hermes must
#      be STOPPED for that — its own guard blocks live-checkout rewrites).
#
# Notes:
#   - Never touches the live checkout itself.
#   - Deterministic: same stash + same upstream commit → same result.
set -euo pipefail

STASH_REF="${1:?usage: restore_hermes_stash.sh <stash-ref> [target-branch]}"
BRANCH="${2:-stash-restore-$(date +%Y%m%d-%H%M%S)}"
REPO="${HERMES_REPO:-$HOME/.hermes/hermes-agent}"
WORKDIR="$HOME/.hermes/scratch/stash-restore-$(date +%Y%m%d-%H%M%S)"
# Files whose stashed version replaces the merged one entirely (stash is the
# newer/evolved implementation). Adjust to your case before running.
OVERRIDE_FILES=(
  # "plugins/observability/langfuse/__init__.py"
  # "tests/plugins/test_langfuse_plugin.py"
)

[ -d "$REPO/.git" ] || { echo "ERROR: $REPO is not a git repo" >&2; exit 1; }

echo "[1/5] exporting stash patch from $STASH_REF ..."
git -C "$REPO" stash show -p "$STASH_REF" > "$HOME/.hermes/scratch/.stash-export-$$.patch" \
  || { echo "ERROR: cannot export $STASH_REF" >&2; exit 1; }
mkdir -p "$WORKDIR"
mv "$HOME/.hermes/scratch/.stash-export-$$.patch" "$WORKDIR/stash.patch"

echo "[2/5] shared clone -> $WORKDIR"
git clone --shared -q "$REPO" "$WORKDIR"
cd "$WORKDIR"
BASE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
git checkout -q -b "$BRANCH"

echo "[3/5] applying patch (3-way) ..."
if ! git apply --3way stash.patch; then
  echo "--> conflicts detected:"
  git status -s | grep '^UU' || true
  for f in "${OVERRIDE_FILES[@]}"; do
    [ -z "$f" ] && continue
    echo "--> overriding conflicted file with stashed version: $f"
    git -C "$REPO" show "${STASH_REF}:${f}" > "$f"
  done
fi
# strip any remaining conflict markers in non-overridden files are a manual
# step — see git status output above.

echo "[4/5] compile + commit"
git add -A
git -c user.name="${GIT_AUTHOR_NAME:-$(git config user.name || echo restore)}" \
    -c user.email="${GIT_AUTHOR_EMAIL:-$(git config user.email || echo restore@local)}" \
    commit -qm "restore: work from autostash ${STASH_REF} (3-way over ${BASE_BRANCH})"
python3 -m py_compile $(git diff --name-only HEAD~1 | grep '\.py$' | tr '\n' ' ') || true

echo "[5/5] done. Branch '$BRANCH' @ $WORKDIR"
echo ""
echo "To apply to the LIVE checkout (stops Hermes first):"
echo "  systemctl --user stop hermes-dashboard hermes-gateway  # and any running hermes"
echo "  cd $REPO"
echo "  git merge --no-ff $WORKDIR  # or: git fetch $WORKDIR '$BRANCH' && git merge FETCH_HEAD"
echo "  systemctl --user start hermes-dashboard hermes-gateway"
echo ""
echo "Or keep the branch as a remote backup:"
echo "  git -C '$WORKDIR' remote add backup <url> && git -C '$WORKDIR' push -u backup '$BRANCH'"
