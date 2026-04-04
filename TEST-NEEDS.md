# TEST-NEEDS.md — pow-the-game

## CRG Grade: B — ACHIEVED 2026-04-04

## Overview

pow-the-game is a research project exploring Steam/gaming infrastructure as
a substrate for distributed combinatorial computation. The project is at Phase 0
(platform research); no game mod workers are deployed yet.

Grade B is achieved via 6 external test targets covering the core components
plus the structural baseline from Grade C.

## Grade B Test Targets (6 required)

| Target | Recipe | Language | File(s) | What it tests |
|--------|--------|----------|---------|---------------|
| T1: Schema validation | `just test-schema` | Nickel | `tests/schema/` | Fragment contract accepts valid inputs; rejects malformed (missing id, HTTP URL, negative timeout) |
| T2: Fragmenter properties | `just test-fragmenter` | Rust/proptest | `crates/fragmenter/` | Partition guarantee: 3^k fragments, distinct seeds, full graph preserved |
| T3: Verifier skeleton | `just test-verifier` | Idris2 | `verifier/` | Type-checks + smoke: valid K3 colouring accepted, invalid rejected |
| T4: GLua worker sim | `just test-worker` | Lua 5.1/LuaJIT | `tests/worker/`, `worker/glua/` | Solvable/unsolvable/timeout cases for 3-colouring kernel |
| T5: Monte Carlo convergence | `just test-montecarlo` | Rust | `crates/fragmenter/src/montecarlo.rs` | pi estimate within 0.05 of π; reproducibility with same RNG seed |
| T6: Coordinator round-trip | `just test-coordinator` | Gleam/gleeunit | `coordinator/` | Fragment lifecycle: register → dispatch → submit → quorum → complete |

## Structural Baseline (Grade C)

| File | Checks |
|------|--------|
| `tests/validate_structure.sh` | 20 checks: RSR files, AI manifest, hooks, CI workflows |

Run: `just test-structure`

## CI Gate

All 6 targets plus the structural baseline run via `just test`. Individual
targets can be run independently — see `just --list`.

## Architecture Decisions

See `docs/DECISIONS.adoc` for D1–D6: platform choice, problem class, verifier
design, coordinator protocol, fragment schema, fraud resistance.

## Still Missing (for CRG A)

- [ ] External feedback (user testing, collaborator review)
- [ ] Phase 1 implementation: real GMod worker + coordinator deployed
- [ ] Idris2 `verifyCorrect` proof body (currently `prf` — trivially correct
  for Phase 0 definition of `ValidColouring`; needs strengthening in Phase 1)
