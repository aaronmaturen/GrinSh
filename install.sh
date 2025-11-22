#!/bin/bash
#
# grinsh installer
# Automatically downloads and installs the latest release
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/aaronmaturen/GrinSh/main/install.sh | bash
#
# Or with options:
#   curl -sSL https://raw.githubusercontent.com/aaronmaturen/GrinSh/main/install.sh | bash -s -- --no-config --add-shell

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO="aaronmaturen/GrinSh"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="grinsh"
CONFIG_FILE="$HOME/.grinshrc"
TEMP_DIR=$(mktemp -d)

# Options
SKIP_CONFIG=false
ADD_TO_SHELLS=false
SKIP_CHECKSUM=false

# Cleanup on exit
trap 'rm -rf "$TEMP_DIR"' EXIT

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

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  grinsh installer${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-config)
                SKIP_CONFIG=true
                shift
                ;;
            --add-shell)
                ADD_TO_SHELLS=true
                shift
                ;;
            --skip-checksum)
                SKIP_CHECKSUM=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
grinsh installer

Usage:
    curl -sSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash
    curl -sSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash -s -- [OPTIONS]

Options:
    --no-config      Skip creating ~/.grinshrc config file
    --add-shell      Automatically add grinsh to /etc/shells
    --skip-checksum  Skip SHA256 checksum verification
    --help           Show this help message

Examples:
    # Standard installation
    curl -sSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash

    # Install and add to shells
    curl -sSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash -s -- --add-shell

    # Install without config file
    curl -sSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash -s -- --no-config
EOF
}

# Check if running on macOS
check_os() {
    print_info "Checking operating system..."
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script only works on macOS"
        exit 1
    fi
    print_success "macOS detected"
}

# Check for required commands
check_dependencies() {
    print_info "Checking dependencies..."

    local missing_deps=()

    for cmd in curl tar shasum; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required commands: ${missing_deps[*]}"
        exit 1
    fi

    print_success "All dependencies found"
}

# Get the latest release version
get_latest_version() {
    print_info "Fetching latest release version..."

    local latest_url="https://api.github.com/repos/$REPO/releases/latest"
    VERSION=$(curl -sSL "$latest_url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -z "$VERSION" ]; then
        print_error "Could not determine latest version"
        print_info "Trying fallback method..."
        VERSION=$(curl -sSL "https://github.com/$REPO/releases/latest" | grep -o 'tag/v[0-9.]*' | head -1 | cut -d'/' -f2)
    fi

    if [ -z "$VERSION" ]; then
        print_error "Could not fetch latest version from GitHub"
        exit 1
    fi

    print_success "Latest version: $VERSION"
}

# Download the release
download_release() {
    print_info "Downloading grinsh $VERSION..."

    local download_url="https://github.com/$REPO/releases/download/$VERSION/grinsh-$VERSION-macos.tar.gz"
    local checksum_url="https://github.com/$REPO/releases/download/$VERSION/grinsh-$VERSION-macos.tar.gz.sha256"

    cd "$TEMP_DIR"

    if ! curl -sSL -f "$download_url" -o "grinsh.tar.gz"; then
        print_error "Failed to download release"
        print_info "URL: $download_url"
        exit 1
    fi

    print_success "Downloaded grinsh-$VERSION-macos.tar.gz"

    # Download checksum
    if [ "$SKIP_CHECKSUM" = false ]; then
        if curl -sSL -f "$checksum_url" -o "grinsh.tar.gz.sha256"; then
            print_success "Downloaded checksum file"
        else
            print_warning "Could not download checksum file (continuing anyway)"
        fi
    fi
}

# Verify checksum
verify_checksum() {
    if [ "$SKIP_CHECKSUM" = true ]; then
        print_warning "Skipping checksum verification"
        return
    fi

    if [ ! -f "$TEMP_DIR/grinsh.tar.gz.sha256" ]; then
        print_warning "No checksum file found, skipping verification"
        return
    fi

    print_info "Verifying checksum..."

    cd "$TEMP_DIR"
    if shasum -a 256 -c grinsh.tar.gz.sha256 2>/dev/null; then
        print_success "Checksum verified"
    else
        print_error "Checksum verification failed!"
        print_warning "The downloaded file may be corrupted or tampered with"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Extract the archive
extract_archive() {
    print_info "Extracting archive..."

    cd "$TEMP_DIR"
    if tar -xzf grinsh.tar.gz; then
        print_success "Archive extracted"
    else
        print_error "Failed to extract archive"
        exit 1
    fi
}

# Install the binary
install_binary() {
    print_info "Installing grinsh to $INSTALL_DIR..."

    if [ ! -f "$TEMP_DIR/$BINARY_NAME" ]; then
        print_error "Binary not found in archive"
        exit 1
    fi

    # Check if we need sudo
    if [ -w "$INSTALL_DIR" ]; then
        cp "$TEMP_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
        chmod +x "$INSTALL_DIR/$BINARY_NAME"
    else
        print_info "Requesting administrator privileges..."
        sudo cp "$TEMP_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
        sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"
    fi

    print_success "Installed $BINARY_NAME to $INSTALL_DIR"
}

# Setup config file
setup_config() {
    if [ "$SKIP_CONFIG" = true ]; then
        print_warning "Skipping config file creation"
        return
    fi

    if [ -f "$CONFIG_FILE" ]; then
        print_warning "Config file already exists at $CONFIG_FILE"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing config file"
            return
        fi
    fi

    print_info "Creating config file at $CONFIG_FILE..."

    if [ -f "$TEMP_DIR/.grinshrc.example" ]; then
        cp "$TEMP_DIR/.grinshrc.example" "$CONFIG_FILE"
        print_success "Created $CONFIG_FILE"
        print_warning "Don't forget to add your Claude API key to $CONFIG_FILE"
    else
        # Create a basic config if example is not in archive
        cat > "$CONFIG_FILE" << 'EOF'
# grinsh configuration file
# Get your API key from https://console.anthropic.com

api_key = "sk-ant-..."
model = "claude-sonnet-4-20250514"
context_limit = 50
EOF
        print_success "Created basic config at $CONFIG_FILE"
        print_warning "Add your Claude API key from https://console.anthropic.com"
    fi
}

# Add to /etc/shells
add_to_shells() {
    if [ "$ADD_TO_SHELLS" = false ]; then
        print_info "To use grinsh as your default shell, run:"
        echo "    sudo echo '$INSTALL_DIR/$BINARY_NAME' | sudo tee -a /etc/shells"
        echo "    chsh -s $INSTALL_DIR/$BINARY_NAME"
        return
    fi

    print_info "Adding grinsh to /etc/shells..."

    if grep -q "$INSTALL_DIR/$BINARY_NAME" /etc/shells 2>/dev/null; then
        print_success "grinsh already in /etc/shells"
    else
        print_info "Requesting administrator privileges..."
        echo "$INSTALL_DIR/$BINARY_NAME" | sudo tee -a /etc/shells > /dev/null
        print_success "Added to /etc/shells"

        print_info "To set as default shell, run:"
        echo "    chsh -s $INSTALL_DIR/$BINARY_NAME"
    fi
}

# Verify installation
verify_installation() {
    print_info "Verifying installation..."

    if ! command -v "$BINARY_NAME" &> /dev/null; then
        print_error "grinsh not found in PATH"
        print_info "You may need to restart your shell or add $INSTALL_DIR to your PATH"
        return 1
    fi

    print_success "grinsh is installed and available in PATH"
}

# Print next steps
print_next_steps() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Installation complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Add your Claude API key to $CONFIG_FILE"
    echo "   Get your key from: https://console.anthropic.com"
    echo ""
    echo "2. Run grinsh:"
    echo "   $ grinsh"
    echo ""
    echo "3. (Optional) Set as default shell:"
    echo "   $ sudo echo '$INSTALL_DIR/$BINARY_NAME' | sudo tee -a /etc/shells"
    echo "   $ chsh -s $INSTALL_DIR/$BINARY_NAME"
    echo ""
    echo "For more information, visit:"
    echo "   https://github.com/$REPO"
    echo ""
}

# Main installation flow
main() {
    parse_args "$@"
    print_header
    check_os
    check_dependencies
    get_latest_version
    download_release
    verify_checksum
    extract_archive
    install_binary
    setup_config
    add_to_shells
    verify_installation
    print_next_steps
}

main "$@"
