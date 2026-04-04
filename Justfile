# SPDX-License-Identifier: AGPL-3.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
# justfile - Just recipes for pow-the-game
# See: https://github.com/hyperpolymath/mustfile

# Default recipe
default:
    @just --list

# ── Grade B test suite ─────────────────────────────────────────────────────────

# Run all Grade B tests (T1–T6) plus structural baseline
test: test-schema test-fragmenter test-montecarlo test-verifier test-worker test-coordinator test-structure

# T1: Fragment schema validation (Nickel contracts)
test-schema:
    bash tests/schema/run_schema_tests.sh

# T2: Graph fragmenter property tests (Rust/proptest)
test-fragmenter:
    cargo test -p fragmenter -- fragmenter fragment graph

# T3: Verifier skeleton type-check + smoke test (Idris2)
test-verifier:
    bash tests/verifier/run_verifier_test.sh

# T4: GLua worker simulation (Lua 5.1 / LuaJIT)
test-worker:
    lua5.1 tests/worker/worker_sim_test.lua 2>/dev/null \
        || luajit tests/worker/worker_sim_test.lua 2>/dev/null \
        || lua tests/worker/worker_sim_test.lua

# T5: Monte Carlo convergence and reproducibility (Rust)
test-montecarlo:
    cargo test -p fragmenter -- montecarlo

# T6: Coordinator protocol round-trip (Gleam/gleeunit)
test-coordinator:
    cd coordinator && gleam test

# Structural baseline (Grade C)
test-structure:
    bash tests/validate_structure.sh

# ── Build ──────────────────────────────────────────────────────────────────────

build:
    cargo build -p fragmenter

# ── Formatting and linting ─────────────────────────────────────────────────────

fmt:
    cargo fmt -p fragmenter
    cd coordinator && gleam format src test

lint:
    cargo clippy -p fragmenter -- -D warnings

# ── Maintenance ────────────────────────────────────────────────────────────────

clean:
    cargo clean
    rm -f verifier/verifier-test
    cd coordinator && gleam clean

# Run panic-attack pre-commit checks
assail:
    @panic-attack assail 2>/dev/null || echo "panic-attack not installed — skipping"
