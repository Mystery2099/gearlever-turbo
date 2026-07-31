#!/usr/bin/env bash
# Compatibility wrapper — prefer: ./setup.sh uninstall
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup.sh" uninstall "$@"
