# Release Process

This document describes how to create releases for grinsh.

## Automatic Version Bumping

**Important:** PRs to `main` are automatically checked for version conflicts. If your PR's VERSION file matches the latest release, the CI will automatically:
- Bump to the next minor version (default)
- Update CHANGELOG.md
- Commit the changes to your PR branch
- Add a comment explaining the change

This ensures every merge to `main` has a unique version number.

## Quick Release (Recommended)

The easiest way to release a new version is using the bump-version script with minor bumps as the default:

```bash
# This will bump minor version (e.g., 1.0.0 → 1.1.0)
make bump

# Or directly:
./scripts/bump-version.sh
```

The script will:
1. ✅ Read current version from VERSION file
2. ✅ Calculate new version (minor bump by default)
3. ✅ Update VERSION file
4. ✅ Update CHANGELOG.md
5. ✅ Create git commit
6. ✅ Create git tag
7. ✅ Push to GitHub
8. ✅ Trigger automated release workflow

## Version Bumping Options

### Using Makefile (Simple)

```bash
make bump          # Bump minor (default): 1.0.0 → 1.1.0
make bump-minor    # Bump minor: 1.0.0 → 1.1.0
make bump-major    # Bump major: 1.0.0 → 2.0.0
make bump-patch    # Bump patch: 1.0.0 → 1.0.1
```

### Using Script Directly

```bash
./scripts/bump-version.sh          # Minor (default)
./scripts/bump-version.sh minor    # Minor
./scripts/bump-version.sh major    # Major
./scripts/bump-version.sh patch    # Patch
./scripts/bump-version.sh 2.5.0    # Specific version
```

### Using GitHub Actions

1. Go to **Actions** → **Bump Version** workflow
2. Click **Run workflow**
3. Select bump type: major, minor (default), or patch
4. Click **Run workflow**

GitHub Actions will:
- Update VERSION file
- Update CHANGELOG.md
- Commit changes
- Create and push tag
- Trigger release build

## Release Workflow

Once a version tag is pushed, the automated workflow:

1. **Builds** universal binary (ARM64 + x86_64)
2. **Creates** release tarball with:
   - grinsh binary
   - .grinshrc.example config
   - Installation README
3. **Generates** SHA256 checksums
4. **Creates** GitHub Release with:
   - Release notes
   - Binary tarball
   - Checksum file
5. **Uploads** artifacts

## Semantic Versioning

grinsh follows [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Breaking changes, incompatible API changes
- **MINOR** (x.X.0): New features, backwards-compatible (DEFAULT)
- **PATCH** (x.x.X): Bug fixes, backwards-compatible

**Default behavior: Minor bumps** are the most common for regular releases with new features.

## Before Releasing

### Checklist

- [ ] All tests pass: `make test`
- [ ] Build succeeds: `make release`
- [ ] Update CHANGELOG.md with changes under `[Unreleased]`
- [ ] README.md is up to date
- [ ] No uncommitted changes
- [ ] On correct branch (usually main)

### Update Changelog

Add your changes under the `[Unreleased]` section:

```markdown
## [Unreleased]

### Added
- New feature X
- New feature Y

### Fixed
- Bug fix Z

### Changed
- Improvement to A
```

The bump-version script will automatically convert this to a versioned release.

## Manual Release (Advanced)

If you need to release manually:

```bash
# 1. Update VERSION
echo "1.2.0" > VERSION

# 2. Update CHANGELOG.md
# Add version and date:
## [1.2.0] - 2025-01-15

# 3. Commit
git add VERSION CHANGELOG.md
git commit -m "Bump version to 1.2.0"

# 4. Tag
git tag -a v1.2.0 -m "Release version 1.2.0"

# 5. Push
git push origin main
git push origin v1.2.0
```

## Hotfix Releases

For urgent bug fixes:

```bash
# Create hotfix branch from main
git checkout main
git checkout -b hotfix/1.0.1

# Make fixes and commit
git commit -m "Fix critical bug"

# Bump patch version
make bump-patch

# Merge back to main
git checkout main
git merge hotfix/1.0.1

# Tag will be created and pushed by bump-patch
```

## Release Schedule

- **Major releases**: As needed for breaking changes
- **Minor releases**: Regular feature releases (default)
- **Patch releases**: Bug fixes as needed

## Rollback a Release

If you need to rollback a release:

```bash
# Delete tag locally and remotely
git tag -d v1.2.0
git push origin :refs/tags/v1.2.0

# Delete GitHub release
# Go to GitHub → Releases → Delete release

# Revert VERSION file
git revert <commit-hash>
```

## Testing a Release Locally

Before pushing a tag, test the release build:

```bash
# Build release
make release

# Test installation
sudo cp .build/release/grinsh /usr/local/bin/grinsh-test
grinsh-test

# Clean up
sudo rm /usr/local/bin/grinsh-test
```

## Troubleshooting

**Problem**: Tag already exists
```bash
# Check existing tags
git tag -l

# Delete local tag
git tag -d v1.2.0

# Delete remote tag
git push origin :refs/tags/v1.2.0
```

**Problem**: Release workflow failed
- Check Actions tab for error logs
- Verify binary builds locally: `make release`
- Check GitHub token permissions
- Retry workflow dispatch manually

**Problem**: Wrong version bumped
```bash
# Undo last commit (before push)
git reset --soft HEAD~1

# Re-run with correct version
./scripts/bump-version.sh <correct-type>
```

## Questions?

See [CONTRIBUTING.md](../CONTRIBUTING.md) for more details or open an issue.
