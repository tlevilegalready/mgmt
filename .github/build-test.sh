#!/usr/bin/env bash
# Build test — mirrors .github/workflows/test.yaml build job steps
set -euo pipefail

make lang resources
make build

echo "=== SUCCESS ==="
./mgmt --version
