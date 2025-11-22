# GitHub Actions Workflows

This directory contains all GitHub Actions workflows for grinsh.

## Workflows Overview

### 🧪 test.yml - Continuous Integration
**Triggers:** Push to main/develop/claude/*, Pull requests to main/develop

Runs on every push and PR to ensure code quality:
- Builds the project
- Runs test suite in parallel
- Generates code coverage
- Runs SwiftLint (non-blocking)
- Builds release binary as artifact

**Jobs:**
- `test` - Run tests and generate coverage
- `lint` - Run SwiftLint for code quality
- `build-release` - Build release binary (only after tests pass)

---

### 🔄 auto-bump-pr.yml - Auto-bump PR Versions
**Triggers:** PRs opened/updated targeting main

Automatically bumps version in PRs if VERSION matches latest release:
- Compares PR's VERSION file with latest release tag
- If they match, automatically bumps to next minor version
- Updates CHANGELOG.md
- Commits changes to PR branch
- Comments on PR explaining the change

**Why:** Prevents accidentally merging code without version bumps.

**Example:**
- Latest release: v1.0.0
- PR has VERSION=1.0.0
- Auto-bumps to VERSION=1.1.0
- Commits to PR branch

---

### 📦 release.yml - Build and Publish Releases
**Triggers:** Git tags (v*), Manual workflow dispatch

Builds and publishes releases to GitHub:
- Builds universal binary (ARM64 + x86_64)
- Creates tarball with binary, config, and README
- Generates SHA256 checksums
- Creates GitHub Release with release notes
- Uploads artifacts

**Manual trigger:** Actions → Release → Run workflow → Enter version

---

### 🏷️ auto-release.yml - Auto-tag on Main Merge
**Triggers:** Push to main (excludes doc-only changes)

Automatically creates release tags when code is merged to main:
- Reads VERSION file
- Checks if tag already exists
- Creates and pushes tag if new
- Triggers release.yml workflow

**Flow:**
1. Code merged to main with VERSION=1.2.0
2. This workflow creates tag v1.2.0
3. Tag creation triggers release.yml
4. Release is built and published

---

### ⬆️ bump-version.yml - Manual Version Bumping
**Triggers:** Manual workflow dispatch only

Provides UI for bumping versions via GitHub Actions:
- Dropdown to select: major, minor (default), patch
- Updates VERSION file
- Updates CHANGELOG.md
- Creates commit and tag
- Pushes to repository
- Triggers release workflow

**Usage:** Actions → Bump Version → Run workflow → Select type

---

### 📚 deploy-docs.yml - Deploy Documentation Site
**Triggers:** Push to main (docs/** changes), Manual workflow dispatch

Deploys the static documentation site to GitHub Pages:
- Publishes contents of `docs/` directory
- Serves site at https://aaronmaturen.github.io/GrinSh
- Automatically updates when docs are modified

**Contents:**
- index.html - Main documentation site
- css/style.css - Brand-compliant dark theme
- js/main.js - Interactive features (copy buttons)
- images/ - Logo and visual assets

---

## Workflow Dependencies

```
┌─────────────────────┐
│  Developer commits  │
│   to feature branch │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Create PR to main │
└──────────┬──────────┘
           │
           ├──────────────────────┐
           │                      │
           ▼                      ▼
┌─────────────────────┐  ┌──────────────────┐
│    test.yml         │  │ auto-bump-pr.yml │
│  Run tests & lint   │  │ Bump if needed   │
└─────────────────────┘  └──────────────────┘
           │
           ▼
┌─────────────────────┐
│   Merge to main     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  auto-release.yml   │
│  Create tag v1.2.0  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│    release.yml      │
│  Build & publish    │
└─────────────────────┘
```

## Running Workflows

### Automatic Workflows
These run automatically and don't require manual intervention:
- `test.yml` - Runs on every push/PR
- `auto-bump-pr.yml` - Runs on PRs to main
- `auto-release.yml` - Runs on merge to main
- `release.yml` - Runs when tag is pushed

### Manual Workflows
These can be triggered manually from GitHub UI:
- `release.yml` - Actions → Release → Run workflow
- `bump-version.yml` - Actions → Bump Version → Run workflow

## Secrets and Permissions

All workflows use `GITHUB_TOKEN` which is automatically provided by GitHub.

Required permissions:
- `contents: write` - For creating tags and releases
- `pull-requests: write` - For commenting on PRs

## Environment

All workflows run on `macos-latest` runners because:
- Swift builds require macOS toolchain
- Native macOS APIs (AppKit, NSPasteboard, etc.)
- Universal binary building (ARM64 + x86_64)

## Best Practices

### For Contributors
- PRs to main will auto-bump version if needed
- Ensure all tests pass before requesting review
- Update CHANGELOG.md under `[Unreleased]` section

### For Maintainers
- Use `make bump` or GitHub UI to create releases
- Review auto-bumped PRs before merging
- Check release workflow succeeded after merge

## Troubleshooting

**Workflow failed on PR:**
- Check test.yml logs in Actions tab
- Fix failing tests locally with `make test`
- Push fixes to PR branch

**Version not auto-bumped:**
- Ensure VERSION file exists
- Check if VERSION already differs from latest release
- Review auto-bump-pr.yml logs

**Release not created:**
- Verify tag was created: `git tag -l`
- Check auto-release.yml succeeded
- Check release.yml logs for build errors

**Manual release needed:**
- Go to Actions → Release → Run workflow
- Or create tag manually: `git tag -a v1.2.0 -m "Release 1.2.0"`

## Workflow Files

```
.github/workflows/
├── auto-bump-pr.yml      # Auto-bump PR versions
├── auto-release.yml      # Auto-tag on main merge
├── bump-version.yml      # Manual version bumping
├── deploy-docs.yml       # Deploy documentation to GitHub Pages
├── release.yml           # Build and publish releases
├── test.yml              # CI testing and linting
└── README.md             # This file
```

## Related Documentation

- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Contribution guidelines
- [documentation/RELEASE_PROCESS.md](../../documentation/RELEASE_PROCESS.md) - Release process details
- [Makefile](../../Makefile) - Build commands
- [Documentation Site](https://aaronmaturen.github.io/GrinSh) - User-facing documentation
