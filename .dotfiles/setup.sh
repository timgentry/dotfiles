#!/usr/bin/env bash
# Main setup orchestrator for dotfiles installation
# Sources all library functions and executes the setup workflow

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source all library files
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/utils.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/state.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/homebrew.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/stow.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/config.sh"

#######################################
# Main setup workflow
#######################################
main() {
    local brewfile_path="${DOTFILES_DIR}/Brewfile"

    log_info "Starting dotfiles setup..."
    log_info "Dotfiles directory: $DOTFILES_DIR"
    log_info "Platform: $(get_platform)"

    # Check if this is first run
    if is_first_run; then
        log_info "First run detected"

        # Request confirmation on first run (unless NONINTERACTIVE)
        if ! confirm "This will install Homebrew, packages, and configure your system. Continue?"; then
            log_info "Setup cancelled by user"
            exit 4
        fi
    else
        log_info "Update detected - running in update mode"
    fi

    # Step 1: Check for Homebrew, install if needed
    log_info "Checking for Homebrew..."
    if HOMEBREW_PREFIX=$(detect_homebrew); then
        log_info "Homebrew found at: $HOMEBREW_PREFIX"
    else
        log_info "Homebrew not found, installing..."
        if [[ -n "${SKIP_HOMEBREW:-}" ]]; then
            log_warning "SKIP_HOMEBREW is set, skipping Homebrew installation"
        else
            if ! install_homebrew; then
                log_error "Homebrew installation failed"
                exit 2
            fi
            # Detect again after installation
            HOMEBREW_PREFIX=$(detect_homebrew)
        fi
    fi

    # Step 2: Configure shell environment for Homebrew
    if [[ -n "$HOMEBREW_PREFIX" ]]; then
        if ! configure_shell_env "$HOMEBREW_PREFIX"; then
            log_error "Failed to configure shell environment"
            exit 2
        fi
    fi

    # Step 3: Install Brewfile packages
    if [[ -f "$brewfile_path" ]]; then
        if [[ -n "${SKIP_HOMEBREW:-}" ]]; then
            log_warning "SKIP_HOMEBREW is set, skipping Brewfile installation"
        else
            if ! install_brewfile "$brewfile_path"; then
                log_error "Brewfile installation failed"
                exit 2
            fi
        fi
    else
        log_warning "Brewfile not found: $brewfile_path"
    fi

    # Step 4: Check that Stow is available
    if ! check_stow_installed; then
        log_error "GNU Stow not found. Please install it: brew install stow"
        exit 2
    fi

    # Step 5: Stow packages
    if [[ -n "${SKIP_STOW:-}" ]]; then
        log_warning "SKIP_STOW is set, skipping stow operations"
    else
        if ! stow_packages; then
            log_warning "Some stow operations failed, but continuing..."
        fi
    fi

    # Step 6: Apply configurations
    if ! apply_configs; then
        log_warning "Some configuration checks failed, but continuing..."
    fi

    # Step 7: Verify all configurations are properly applied
    if ! verify_configs; then
        log_warning "Some verification checks failed, but setup completed"
    fi

    # Step 8: Save state
    if ! save_state; then
        log_warning "Failed to save state, but setup completed"
    fi

    # Success!
    log_info "Setup completed successfully!"
    echo ""
    echo "========================================="
    echo "  ✅ Dotfiles setup complete!"
    echo "========================================="
    echo ""
    echo "Next steps:"
    echo "  1. Restart your shell: exec \$SHELL"
    echo "  2. Verify PATH includes ~/bin: echo \$PATH"
    echo "  3. Test utility scripts: gh-open (in a git repository)"
    echo ""

    return 0
}

# Cleanup on exit
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Setup failed with exit code: $exit_code"
        echo ""
        echo "Check the log file for details: ~/.dotfiles/setup.log"
    fi
}

trap cleanup EXIT

# Execute main
main "$@"
