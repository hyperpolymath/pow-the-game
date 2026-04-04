# TEST-NEEDS.md — pow-the-game

## CRG Grade: C — ACHIEVED 2026-04-04

## Current Test State

| Category | Count | Notes |
|----------|-------|-------|
| Structural tests | 20 | `tests/validate_structure.sh` — all passing |
| Unit tests | 0 | No source code yet (infrastructure phase) |
| Integration tests | 0 | No source code yet |

## What's Covered

- [x] Core RSR files present: README.adoc, LICENSE, SECURITY.md, Justfile
- [x] AI manifest (`0-AI-MANIFEST.a2ml`) present
- [x] `.machine_readable/` directory present
- [x] All 4 hook scripts present, executable, and syntax-valid
- [x] `.github/workflows/` present with ≥5 workflow files (14 found)

## CI Gate

```bash
bash tests/validate_structure.sh
```

## Known Failures / Limitations

- No source code exists — project is in infrastructure setup phase
- All test coverage is structural validation only
- Project specification not yet uploaded (noted in README.adoc)

## Still Missing (for CRG C → implementation)

- [ ] Project specification document
- [ ] Source code (game mechanics)
- [ ] Unit tests for game logic once implemented
- [ ] `just test` recipe in Justfile wired to test runner

## Run Tests

```bash
bash tests/validate_structure.sh
```
