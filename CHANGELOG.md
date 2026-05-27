<!--
SPDX-License-Identifier: MPL-2.0
SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath)
-->

# Changelog

All notable changes to `pow-the-game` will be documented in this file.

This file is generated from conventional commits by the
[`changelog-reusable.yml`](https://github.com/hyperpolymath/standards/blob/main/.github/workflows/changelog-reusable.yml)
workflow (`hyperpolymath/standards#206`). Adopt the workflow in this repo's CI to keep this file in sync automatically — see
[`templates/cliff.toml`](https://github.com/hyperpolymath/standards/blob/main/templates/cliff.toml)
for the canonical config.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- feat(crg): add crg-grade and crg-badge justfile recipes
- feat: implement Grade B test suite (6 external targets)

### Fixed

- fix(licence): normalise son's AGPL + clear scaffold leak (#35)
- fix(ci): sync hypatia-scan.yml to canonical (kill cd-scanner build drift) (#33)
- fix(ci): build Hypatia escript from repo root (estate dogfood drift)
- fix(ci): Phase-2 fleet submission must not fail the security gate (#32)
- fix(ci): hypatia-scan workdir (${{ env.HOME }} resolves empty) (#31)
- fix(ci): hypatia-scan.yml -- pass GITHUB_TOKEN, use --exit-zero (hyperpolymath/hypatia#213) (#25)
- fix(ci): rsr-antipattern duplicate heredoc + setup-beam ubuntu24 (#27)
- fix(ci): move secret-scanner Cargo.toml gate from job-level if: to step-level (#29)
- fix(codeql): switch language matrix to 'actions' (no JS/TS in repo) (#28)

### Documentation

- docs(readme): add SPDX header and/or standard badges
- docs(explainme): add EXPLAINME.adoc
- docs: reframe as Steam/gaming distributed compute research project

### CI

- ci(secret-scanner): drop duplicate --fail from trufflehog extra_args (#24)
- ci: bump actions/upload-artifact SHA to current v4 (#23)
- ci: fix workflow-linter YAML parse error + self-flag bug
- ci: fix workflow-linter self-flag bug
- ci(antipattern): fix top-level dir matching + benchmarks/lsp/bench filename allowlists (#20)

## Pre-history

Prior commits to this file's introduction are recorded in git history but not formally classified into Keep-a-Changelog sections. To backfill, run `git cliff -o CHANGELOG.md` locally using the canonical [`cliff.toml`](https://github.com/hyperpolymath/standards/blob/main/templates/cliff.toml) — this is one-shot mechanical work.

---

<!-- This file was seeded by the 2026-05-26 estate tech-debt audit follow-up (Row-2 Phase 3); see [`hyperpolymath/standards/docs/audits/2026-05-26-estate-documentation-debt.md`](https://github.com/hyperpolymath/standards/blob/main/docs/audits/2026-05-26-estate-documentation-debt.md). -->
