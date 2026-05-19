#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Structural smoke tests for pow-the-game.
# Validates RSR scaffolding, hook scripts, and workflow presence.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

check() {
    local desc="$1" result="$2"
    if [ "$result" = "ok" ]; then
        echo "PASS: $desc"; PASS=$((PASS+1))
    else
        echo "FAIL: $desc"; FAIL=$((FAIL+1))
    fi
}

# --- Core RSR files ---
[ -f "$REPO_ROOT/README.adoc" ]        && check "README.adoc present"         "ok" || check "README.adoc present"         "fail"
[ -f "$REPO_ROOT/LICENSE" ]            && check "LICENSE present"              "ok" || check "LICENSE present"              "fail"
[ -f "$REPO_ROOT/SECURITY.md" ]        && check "SECURITY.md present"         "ok" || check "SECURITY.md present"         "fail"
[ -f "$REPO_ROOT/Justfile" ]           && check "Justfile present"             "ok" || check "Justfile present"             "fail"
[ -f "$REPO_ROOT/0-AI-MANIFEST.a2ml" 2>/dev/null ] || [ -f "$REPO_ROOT/AI.a2ml" 2>/dev/null ] \
    && check "AI manifest present" "ok" || check "AI manifest present" "fail"

# --- Machine-readable metadata ---
[ -d "$REPO_ROOT/.machine_readable" ]  && check ".machine_readable/ present"  "ok" || check ".machine_readable/ present"  "fail"

# --- Hook scripts are executable and syntactically valid ---
for hook in validate-codeql validate-permissions validate-sha-pins validate-spdx; do
    script="$REPO_ROOT/hooks/$hook.sh"
    [ -f "$script" ]       && check "hooks/$hook.sh exists"      "ok" || check "hooks/$hook.sh exists"      "fail"
    [ -x "$script" ]       && check "hooks/$hook.sh executable"  "ok" || check "hooks/$hook.sh executable"  "fail"
    bash -n "$script" 2>/dev/null \
                           && check "hooks/$hook.sh syntax valid" "ok" || check "hooks/$hook.sh syntax valid" "fail"
done

# --- CI workflows present ---
[ -d "$REPO_ROOT/.github/workflows" ]  && check ".github/workflows/ present"  "ok" || check ".github/workflows/ present"  "fail"
wf_count=$(ls "$REPO_ROOT/.github/workflows/"*.yml 2>/dev/null | wc -l)
[ "$wf_count" -ge 5 ]                  && check "≥5 workflow files present ($wf_count)" "ok" \
                                       || check "≥5 workflow files present ($wf_count)" "fail"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
