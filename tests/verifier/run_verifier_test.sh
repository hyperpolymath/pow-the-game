#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# run_verifier_test.sh — Idris2 verifier type-check + smoke test
#
# Checks:
#   1. idris2 is available on PATH
#   2. The package type-checks cleanly via the .ipkg file
#   3. The smoke-test main compiles and runs correctly
#
# Exit code: 0 = all checks pass, 1 = any check fails

set -euo pipefail

PASS=0
FAIL=0
VERIFIER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/verifier"

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

# Check 1: idris2 available
if command -v idris2 >/dev/null 2>&1; then
    pass "idris2 available ($(idris2 --version 2>&1 | head -1))"
else
    fail "idris2 not found on PATH — install via pack or system package manager"
    echo ""
    echo "Results: 0 passed, 1 failed"
    exit 1
fi

cd "$VERIFIER_DIR"

# Check 2: package type-checks via .ipkg (respects sourcedir = "src")
if idris2 --typecheck pow-verifier.ipkg 2>/dev/null; then
    pass "pow-verifier.ipkg type-checks successfully"
else
    fail "Idris2 type-check failed"
    idris2 --typecheck pow-verifier.ipkg
fi

# Check 3: Main compiles and runs
BUILD_OUT=$(idris2 --build pow-verifier.ipkg 2>&1) || true
if [ -f "build/exec/pow-verifier-test" ]; then
    if RESULT=$(./build/exec/pow-verifier-test 2>&1); then
        pass "Verifier smoke tests passed: $RESULT"
    else
        fail "Verifier smoke test execution failed: $RESULT"
    fi
else
    # Fallback: compile Main directly with correct source dir
    if idris2 --no-banner --source-dir src -p contrib -o verifier-test Main 2>/dev/null && \
       RESULT=$(./verifier-test 2>&1); then
        pass "Verifier smoke tests passed (fallback compile): $RESULT"
        rm -f verifier-test
    else
        fail "Verifier smoke test build/run failed"
        echo "  Build output: $BUILD_OUT"
        rm -f verifier-test 2>/dev/null || true
    fi
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
