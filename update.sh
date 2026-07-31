#!/usr/bin/env bash
# Compatibility wrapper — prefer: ./setup.sh update
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup.sh" update "$@"
