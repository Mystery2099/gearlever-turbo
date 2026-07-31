#!/usr/bin/env bash
# Update a gearlever-turbo git clone (ff-only) and reinstall to ~/.local/bin.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v git >/dev/null 2>&1; then
  echo "error: git is required for ./update.sh" >&2
  echo "Tip: update the installed binary with: gearlever-turbo --self-update" >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: not a git checkout (${SCRIPT_DIR})" >&2
  echo "Tip: update the installed binary with: gearlever-turbo --self-update" >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: working tree has uncommitted changes; commit or stash first." >&2
  git status --short >&2
  exit 1
fi

before="unknown"
if [[ -x "${SCRIPT_DIR}/gearlever-turbo" ]]; then
  before="$("${SCRIPT_DIR}/gearlever-turbo" --version 2>/dev/null || echo unknown)"
fi

echo "Fetching updates…"
git fetch origin
if ! git pull --ff-only; then
  echo "error: could not fast-forward (branch diverged from origin)." >&2
  echo "Resolve with git rebase/merge, or use: gearlever-turbo --self-update" >&2
  exit 1
fi

"${SCRIPT_DIR}/install.sh"

after="unknown"
if [[ -x "${SCRIPT_DIR}/gearlever-turbo" ]]; then
  after="$("${SCRIPT_DIR}/gearlever-turbo" --version 2>/dev/null || echo unknown)"
fi

echo
echo "Clone/install update complete."
echo "  Before: ${before}"
echo "  After:  ${after}"
