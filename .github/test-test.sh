#!/usr/bin/env bash
# Test runner -- mirrors .github/workflows/test.yaml go-tests jobs
# Runs all test blocks: basic, race, shell
set -euo pipefail

# ---- Install linting tools --------------------------------------------------------------------------------------------------
echo "=== Installing linting tools ==="
gem install mdl -v 0.15.0 --no-document

# ---- Generate language frontend + WASM --------------------------------------------------------------------------
echo "=== Generating language frontend + WASM ==="
make lang resources

# ---- Build test tools ------------------------------------------------------------------------------------------------------------
echo "=== Building test tools ==="
make -C test

# ---- Build mgmt ------------------------------------------------------------------------------------------------------------------------
echo "=== Building mgmt ==="
make build

# ---- Run Group 1 (everything except slow packages) ----------------------------------------------------------
echo "=== Running Group 1 (fast packages) ==="
TEST_BLOCK=basic TEST_GROUP=1 make test

# ---- Run Group 2 (slow packages) + Shell --------------------------------------------------------------------
echo "=== Running Group 2 (slow packages) + Shell ==="
TEST_BLOCK=basic TEST_GROUP=2 make test
TEST_BLOCK=shell make test

# ---- Run race block (weekly + on Go code changes in CI) -----------------------------------------------------
echo "=== Running race block ==="
TEST_BLOCK=race make test

echo "=== ALL TESTS PASSED ==="
