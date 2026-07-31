#!/usr/bin/env bash
# Clone helper: install / update / uninstall gearlever-turbo to ~/.local/bin.
# For people who only have the installed binary, prefer:
#   gearlever-turbo --self-update
#   gearlever-turbo --self-uninstall
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SCRIPT_DIR}/gearlever-turbo"
DEST_DIR="${HOME}/.local/bin"
DEST="${DEST_DIR}/gearlever-turbo"

usage() {
  cat <<EOF
Usage: ./setup.sh <command>

Commands:
  install     Copy gearlever-turbo to ~/.local/bin
  update      git pull --ff-only this clone, then install
  uninstall   Remove ~/.local/bin/gearlever-turbo

Aliases (same as the commands above):
  ./install.sh
  ./update.sh
  ./uninstall.sh

Installed-binary shortcuts (no clone required):
  gearlever-turbo --self-update
  gearlever-turbo --self-uninstall
EOF
}

cmd_install() {
  if [[ ! -f "$SRC" ]]; then
    echo "error: gearlever-turbo not found next to setup.sh (${SRC})" >&2
    exit 1
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "error: python3 is required but was not found on PATH." >&2
    exit 1
  fi
  if ! python3 -c 'import sys; raise SystemExit(0 if sys.version_info[:2] >= (3, 10) else 1)'; then
    echo "error: Python 3.10+ is required (found $(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])'))." >&2
    exit 1
  fi

  mkdir -p "$DEST_DIR"
  install -m 755 "$SRC" "$DEST"

  echo "Installed: ${DEST}"

  if ! command -v aria2c >/dev/null 2>&1; then
    echo
    echo "Note: aria2c was not found. Full downloads need aria2."
    if command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1; then
      echo "  sudo apt install aria2"
    elif command -v dnf >/dev/null 2>&1; then
      echo "  sudo dnf install aria2"
    elif command -v pacman >/dev/null 2>&1; then
      echo "  sudo pacman -S aria2"
    else
      echo "  install the aria2 package for your distribution"
    fi
  fi

  case ":${PATH}:" in
    *":${DEST_DIR}:"*)
      echo
      echo "Ready. Try:"
      echo "  gearlever-turbo --check"
      echo "  gearlever-turbo"
      ;;
    *)
      echo
      echo "Add ~/.local/bin to your PATH, then open a new shell:"
      echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
      echo "  # or for zsh:"
      echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
      echo
      echo "Or run directly:"
      echo "  ${DEST} --check"
      ;;
  esac
}

cmd_update() {
  cd "$SCRIPT_DIR"

  if ! command -v git >/dev/null 2>&1; then
    echo "error: git is required for ./setup.sh update" >&2
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
  if [[ -x "$SRC" ]]; then
    before="$("$SRC" --version 2>/dev/null || echo unknown)"
  fi

  echo "Fetching updates…"
  git fetch origin
  if ! git pull --ff-only; then
    echo "error: could not fast-forward (branch diverged from origin)." >&2
    echo "Resolve with git rebase/merge, or use: gearlever-turbo --self-update" >&2
    exit 1
  fi

  cmd_install

  after="unknown"
  if [[ -x "$SRC" ]]; then
    after="$("$SRC" --version 2>/dev/null || echo unknown)"
  fi

  echo
  echo "Clone/install update complete."
  echo "  Before: ${before}"
  echo "  After:  ${after}"
}

cmd_uninstall() {
  if [[ ! -e "$DEST" ]]; then
    echo "Nothing to remove: ${DEST} not found"
    exit 0
  fi

  if [[ ! -w "$DEST" ]] || [[ ! -w "$DEST_DIR" ]]; then
    echo "error: no write permission for ${DEST}" >&2
    exit 1
  fi

  rm -f "$DEST"
  echo "Removed ${DEST}"
  echo "GearLever AppImages were not touched."
  echo
  echo "If you keep a clone, you can delete that directory separately."
  echo "To reinstall later: ./setup.sh install"
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    install)
      shift || true
      cmd_install "$@"
      ;;
    update)
      shift || true
      cmd_update "$@"
      ;;
    uninstall)
      shift || true
      cmd_uninstall "$@"
      ;;
    -h|--help|help|"")
      usage
      if [[ -z "$cmd" ]]; then
        exit 1
      fi
      ;;
    *)
      echo "error: unknown command: ${cmd}" >&2
      echo >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
