#!/usr/bin/env bash
# Remote bootstrap script for dotfiles installation
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/install.sh)

set -euo pipefail

# Configuration
readonly DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/timgentry/dotfiles.git}"
readonly DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/.dotfiles}"
readonly DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"

# Colors for output
readonly COLOR_RESET='\033[0m'
readonly COLOR_INFO='\033[0;36m'
readonly COLOR_ERROR='\033[0;31m'

#######################################
# Log informational message
#######################################
info() {
    echo -e "${COLOR_INFO}=>${COLOR_RESET} $*"
}

#######################################
# Log error message and exit
#######################################
error() {
    echo -e "${COLOR_ERROR}ERROR:${COLOR_RESET} $*" >&2
    exit 1
}

#######################################
# Check for required dependencies
#######################################
check_dependencies() {
    info "Checking dependencies..."

    if ! command -v git &>/dev/null; then
        error "git is required but not installed. Please install git and try again."
    fi

    if ! command -v curl &>/dev/null; then
        error "curl is required but not installed. Please install curl and try again."
    fi

    info "All dependencies present"
}

#######################################
# Detect platform
#######################################
detect_platform() {
    local os
    case "$(uname -s)" in
        Darwin*) os="macOS" ;;
        Linux*)  os="Linux" ;;
        *)
            error "Unsupported operating system: $(uname -s)"
            ;;
    esac

    info "Detected platform: $os ($(uname -m))"
}

#######################################
# Clone or update dotfiles repository
#######################################
clone_or_update_repo() {
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        info "Dotfiles repository already exists at: $DOTFILES_DIR"
        info "Updating repository..."

        cd "$DOTFILES_DIR"
        if git pull origin "$DOTFILES_BRANCH"; then
            info "Repository updated successfully"
        else
            error "Failed to update repository"
        fi
    else
        info "Cloning dotfiles repository..."
        info "Repository: $DOTFILES_REPO"
        info "Destination: $DOTFILES_DIR"

        if git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"; then
            info "Repository cloned successfully"
        else
            error "Failed to clone repository"
        fi
    fi
}

#######################################
# Execute setup script
#######################################
run_setup() {
    local setup_script="${DOTFILES_DIR}/.dotfiles/setup.sh"

    if [[ ! -f "$setup_script" ]]; then
        error "Setup script not found: $setup_script"
    fi

    info "Running setup script..."
    chmod +x "$setup_script"

    if "$setup_script"; then
        info "Setup completed successfully!"
        echo ""
        echo "🎉 Your dotfiles have been installed!"
        echo ""
        echo "Next steps:"
        echo "  1. Restart your shell: exec \$SHELL"
        echo "  2. Verify installation: brew --version"
        echo "  3. Test utility scripts: gh-open (in a git repository)"
        return 0
    else
        error "Setup script failed with exit code: $?"
    fi
}

#######################################
# Main installation workflow
#######################################
main() {
    echo "================================"
    echo "  Dotfiles Installation"
    echo "================================"
    echo ""

    check_dependencies
    detect_platform
    clone_or_update_repo
    run_setup

    exit 0
}

# Execute main function
# This is at the end to prevent partial execution if download is interrupted
main "$@"
