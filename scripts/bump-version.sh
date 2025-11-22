#!/bin/bash
#
# Version bumping script for grinsh
# Automatically increments version and updates VERSION file
#
# Usage:
#   ./scripts/bump-version.sh         # Bump minor version (default)
#   ./scripts/bump-version.sh minor   # Bump minor version
#   ./scripts/bump-version.sh major   # Bump major version
#   ./scripts/bump-version.sh patch   # Bump patch version
#   ./scripts/bump-version.sh 2.0.0   # Set specific version

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERSION_FILE="VERSION"
CHANGELOG_FILE="CHANGELOG.md"

# Print functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if VERSION file exists
if [ ! -f "$VERSION_FILE" ]; then
    print_error "VERSION file not found"
    exit 1
fi

# Read current version
CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')

if [ -z "$CURRENT_VERSION" ]; then
    print_error "VERSION file is empty"
    exit 1
fi

print_info "Current version: $CURRENT_VERSION"

# Parse version components
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

# Determine bump type (default to minor)
BUMP_TYPE="${1:-minor}"

case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        NEW_VERSION="$MAJOR.$MINOR.$PATCH"
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        NEW_VERSION="$MAJOR.$MINOR.$PATCH"
        ;;
    patch)
        PATCH=$((PATCH + 1))
        NEW_VERSION="$MAJOR.$MINOR.$PATCH"
        ;;
    [0-9]*.[0-9]*.[0-9]*)
        # Specific version provided
        NEW_VERSION="$BUMP_TYPE"
        ;;
    *)
        print_error "Invalid bump type: $BUMP_TYPE"
        echo ""
        echo "Usage: $0 [major|minor|patch|X.Y.Z]"
        echo ""
        echo "Examples:"
        echo "  $0          # Bump minor (default)"
        echo "  $0 minor    # Bump minor version"
        echo "  $0 major    # Bump major version"
        echo "  $0 patch    # Bump patch version"
        echo "  $0 2.0.0    # Set specific version"
        exit 1
        ;;
esac

print_success "New version: $NEW_VERSION"

# Check if version already exists as a git tag
if git rev-parse "v$NEW_VERSION" >/dev/null 2>&1; then
    print_error "Version v$NEW_VERSION already exists as a git tag"
    exit 1
fi

# Confirm with user
echo ""
read -p "Bump version from $CURRENT_VERSION to $NEW_VERSION? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Aborted"
    exit 0
fi

# Update VERSION file
echo "$NEW_VERSION" > "$VERSION_FILE"
print_success "Updated $VERSION_FILE"

# Update CHANGELOG.md if it exists
if [ -f "$CHANGELOG_FILE" ]; then
    # Get current date
    CURRENT_DATE=$(date +%Y-%m-%d)

    # Check if there's an [Unreleased] section
    if grep -q "\[Unreleased\]" "$CHANGELOG_FILE"; then
        # Replace [Unreleased] with the new version
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/## \[Unreleased\]/## [Unreleased]\n\n## [$NEW_VERSION] - $CURRENT_DATE/" "$CHANGELOG_FILE"
        else
            # Linux
            sed -i "s/## \[Unreleased\]/## [Unreleased]\n\n## [$NEW_VERSION] - $CURRENT_DATE/" "$CHANGELOG_FILE"
        fi
        print_success "Updated $CHANGELOG_FILE"
    else
        print_warning "No [Unreleased] section found in $CHANGELOG_FILE"
        print_info "You may want to manually update the changelog"
    fi
fi

# Git operations
print_info "Creating git commit..."

git add "$VERSION_FILE"
[ -f "$CHANGELOG_FILE" ] && git add "$CHANGELOG_FILE"

git commit -m "Bump version to $NEW_VERSION"
print_success "Created commit"

# Ask if user wants to create a tag
echo ""
read -p "Create git tag v$NEW_VERSION? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git tag -a "v$NEW_VERSION" -m "Release version $NEW_VERSION"
    print_success "Created tag v$NEW_VERSION"

    echo ""
    read -p "Push to remote? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        CURRENT_BRANCH=$(git branch --show-current)
        git push origin "$CURRENT_BRANCH"
        git push origin "v$NEW_VERSION"
        print_success "Pushed to remote"

        echo ""
        print_success "Version bump complete!"
        print_info "The release workflow will automatically build and publish the release"
    else
        echo ""
        print_success "Version bump complete!"
        print_warning "Don't forget to push your changes:"
        echo "  git push origin $(git branch --show-current)"
        echo "  git push origin v$NEW_VERSION"
    fi
else
    echo ""
    print_success "Version bumped to $NEW_VERSION"
    print_warning "No tag created. To create and push later:"
    echo "  git tag -a v$NEW_VERSION -m 'Release version $NEW_VERSION'"
    echo "  git push origin $(git branch --show-current)"
    echo "  git push origin v$NEW_VERSION"
fi
