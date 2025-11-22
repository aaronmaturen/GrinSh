.PHONY: help build test clean install release bump-major bump-minor bump-patch

# Default target
help:
	@echo "grinsh - Makefile targets"
	@echo ""
	@echo "Development:"
	@echo "  make build        Build debug binary"
	@echo "  make test         Run test suite"
	@echo "  make clean        Clean build artifacts"
	@echo ""
	@echo "Release:"
	@echo "  make release      Build release binary"
	@echo "  make install      Install to /usr/local/bin (requires sudo)"
	@echo ""
	@echo "Version Management (defaults to minor bumps):"
	@echo "  make bump         Bump minor version (1.0.0 → 1.1.0)"
	@echo "  make bump-minor   Bump minor version (1.0.0 → 1.1.0)"
	@echo "  make bump-major   Bump major version (1.0.0 → 2.0.0)"
	@echo "  make bump-patch   Bump patch version (1.0.0 → 1.0.1)"

# Build targets
build:
	@echo "Building debug binary..."
	swift build

release:
	@echo "Building release binary..."
	swift build -c release

# Test target
test:
	@echo "Running tests..."
	swift test --parallel

test-verbose:
	@echo "Running tests (verbose)..."
	swift test -v --parallel

# Clean target
clean:
	@echo "Cleaning build artifacts..."
	swift package clean
	rm -rf .build

# Install target
install: release
	@echo "Installing grinsh to /usr/local/bin..."
	sudo cp .build/release/grinsh /usr/local/bin/grinsh
	sudo chmod +x /usr/local/bin/grinsh
	@echo "✓ Installed successfully"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Create ~/.grinshrc with your Claude API key"
	@echo "  2. Run 'grinsh' to start"

# Version bumping targets
bump: bump-minor

bump-minor:
	@echo "Bumping minor version..."
	./scripts/bump-version.sh minor

bump-major:
	@echo "Bumping major version..."
	./scripts/bump-version.sh major

bump-patch:
	@echo "Bumping patch version..."
	./scripts/bump-version.sh patch

# Uninstall target
uninstall:
	@echo "Removing grinsh from /usr/local/bin..."
	sudo rm -f /usr/local/bin/grinsh
	@echo "✓ Uninstalled"
	@echo ""
	@echo "Config file (~/.grinshrc) and database (~/.grinsh/) were not removed."
	@echo "To remove them:"
	@echo "  rm ~/.grinshrc"
	@echo "  rm -rf ~/.grinsh"
