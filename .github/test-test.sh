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

# ---- Run basic block (lint + tests) --------------------------------------------------------------------------------
echo "=== Running basic block ==="
TEST_BLOCK=basic make test

# ---- Run race block ----------------------------------------------------------------------------------------------------------------
echo "=== Running race block ==="
TEST_BLOCK=race make test

# ---- Run shell block --------------------------------------------------------------------------------------------------------------
echo "=== Running shell block ==="
TEST_BLOCK=shell make test

echo "=== ALL TESTS PASSED ==="
