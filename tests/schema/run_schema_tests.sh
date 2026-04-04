#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# run_schema_tests.sh — Nickel fragment contract tests (Target 1 — Grade B)
#
# Positive tests: fragment_contract_test.ncl must evaluate without error.
# Negative tests: reject_*.ncl files must FAIL (contract violation expected).
#
# Exit code: 0 = all tests pass, 1 = any test fails.

set -euo pipefail

PASS=0
FAIL=0
SCHEMA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

# Check nickel is available
if ! command -v nickel >/dev/null 2>&1; then
    echo "SKIP: nickel not found on PATH — install from https://nickel-lang.org"
    echo "Results: 0 passed, 0 failed (skipped — nickel unavailable)"
    exit 0
fi

# Positive test: valid fragments must be accepted
if nickel eval "$SCHEMA_DIR/fragment_contract_test.ncl" >/dev/null 2>&1; then
    pass "valid 3-colouring and Monte Carlo fragments accepted"
else
    fail "valid fragments rejected — contract is too strict"
    nickel eval "$SCHEMA_DIR/fragment_contract_test.ncl"
fi

# Negative tests: these files must FAIL contract evaluation
for reject_file in "$SCHEMA_DIR"/reject_*.ncl; do
    name="$(basename "$reject_file" .ncl)"
    if nickel eval "$reject_file" >/dev/null 2>&1; then
        fail "$name — expected contract violation but evaluation succeeded"
    else
        pass "$name — correctly rejected malformed input"
    fi
done

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
