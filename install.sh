#!/usr/bin/env bash
# Install gearlever-turbo to ~/.local/bin (no root required).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SCRIPT_DIR}/gearlever-turbo"
DEST_DIR="${HOME}/.local/bin"
DEST="${DEST_DIR}/gearlever-turbo"

if [[ ! -f "$SRC" ]]; then
  echo "error: gearlever-turbo not found next to install.sh (${SRC})" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required but was not found on PATH." >&2
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
