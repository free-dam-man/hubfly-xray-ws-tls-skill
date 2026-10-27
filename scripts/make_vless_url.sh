#!/usr/bin/env bash
# Usage:
#   UUID=... HOST=xray.example.hubfly.app WSPATH=/tk-rail NAME=Hubfly-US-01 ./scripts/make_vless_url.sh
set -euo pipefail
UUID="${UUID:?set UUID}"
HOST="${HOST:?set HOST (Hubfly SSL subdomain)}"
PORT="${PORT:-443}"
WSPATH="${WSPATH:-/tk-rail}"
NAME="${NAME:-Hubfly}"
ENC=$(WSPATH="$WSPATH" python3 -c "import urllib.parse,os; print(urllib.parse.quote(os.environ['WSPATH'], safe=''))")
echo "vless://${UUID}@${HOST}:${PORT}?encryption=none&security=tls&type=ws&host=${HOST}&path=${ENC}&sni=${HOST}#${NAME}"
