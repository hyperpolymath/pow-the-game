# pow-the-game Roadmap

## Current Status

The repository is in its initial setup phase with secure SCM infrastructure established.

### Completed

- [x] Hub-and-spoke mirror workflow (GitHub -> GitLab, Codeberg, Bitbucket)
- [x] SSH host key verification for all mirror targets
- [x] Pinned GitHub Actions with commit SHA hashes
- [x] Minimal permissions (`read-all`) for workflows
- [x] Concurrency control to prevent race conditions
- [x] Job timeout limits (10 minutes per mirror)
- [x] Commit signing with SSH keys

---

## Phase 1: Infrastructure & Security Foundation

### SCM Configuration
- [ ] Add `.gitignore` for project-specific exclusions
- [ ] Add `.gitattributes` for line ending and diff handling
- [ ] Configure branch protection rules on main/master
- [ ] Set up CODEOWNERS file

### CI/CD Enhancements
- [ ] Add workflow status badges to README
- [ ] Configure Dependabot for action version updates
- [ ] Add security scanning workflow (CodeQL or similar)
- [ ] Add license compliance checking

### Documentation
- [ ] Create README.md with project overview
- [ ] Add CONTRIBUTING.md with development guidelines
- [ ] Add SECURITY.md with vulnerability reporting policy
- [ ] Add LICENSE file (AGPL-3.0-or-later as indicated)
- [ ] Create issue templates
- [ ] Create pull request templates

---

## Phase 2: Development Environment

### Build System
- [ ] Initialize project with appropriate build tooling
- [ ] Configure linting and formatting
- [ ] Set up pre-commit hooks
- [ ] Add CI workflow for builds and tests

### Quality Assurance
- [ ] Add automated testing framework
- [ ] Configure code coverage reporting
- [ ] Set up integration testing

---

## Phase 3: Game Development

*(To be expanded based on game design decisions)*

- [ ] Define game concept and mechanics
- [ ] Set up game engine/framework
- [ ] Implement core game loop
- [ ] Add asset pipeline
- [ ] Implement game features

---

## Security Checklist

### Already Implemented
- [x] Pinned action versions (commit SHA)
- [x] SSH host key verification (prevents MITM)
- [x] Minimal workflow permissions
- [x] Secret-based credential management
- [x] Concurrency controls
- [x] Job timeouts

### Pending
- [ ] Enable Dependabot security alerts
- [ ] Add secret scanning
- [ ] Configure branch protection rules
- [ ] Add SECURITY.md policy
- [ ] Enable GitHub Advanced Security (if available)

---

## Mirror Configuration Status

| Platform  | Status    | Enable Variable          |
|-----------|-----------|--------------------------|
| GitLab    | Ready     | `GITLAB_MIRROR_ENABLED`  |
| Codeberg  | Ready     | `CODEBERG_MIRROR_ENABLED`|
| Bitbucket | Ready     | `BITBUCKET_MIRROR_ENABLED`|

### Required Secrets
- `GITLAB_SSH_KEY` - Deploy key for GitLab mirror
- `CODEBERG_SSH_KEY` - Deploy key for Codeberg mirror
- `BITBUCKET_SSH_KEY` - Deploy key for Bitbucket mirror

---

*Last updated: 2025-12-17*
