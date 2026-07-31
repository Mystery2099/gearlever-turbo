#!/usr/bin/env bash
# Remove the user install of gearlever-turbo from ~/.local/bin (no root required).
# Does not delete a git clone or any GearLever AppImages.
set -euo pipefail

DEST_DIR="${HOME}/.local/bin"
DEST="${DEST_DIR}/gearlever-turbo"

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
echo "To reinstall later: ./install.sh"
