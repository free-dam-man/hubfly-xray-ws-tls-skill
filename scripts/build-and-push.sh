#!/usr/bin/env bash
# Local build + push to an ephemeral ttl.sh tag (no registry account).
# After ttl.sh expiry (~24h), re-run before recreating a Hubfly container.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${1:-ttl.sh/hfx2-$(openssl rand -hex 3):24h}"
echo "building multi-arch -> $TAG"
docker buildx build --platform linux/amd64,linux/arm64 \
  -t "$TAG" --push "$ROOT/deploy"
echo "IMAGE=$TAG"
echo "Paste this image URL into Hubfly → Create from image."
