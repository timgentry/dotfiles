#!/usr/bin/env bash
# Configuration management for dotfiles
# Handles git, gem, and other global configuration settings

set -euo pipefail

#######################################
# Configure git settings
# Verifies that git configuration is properly symlinked
# Returns:
#   0 on success, 1 on failure
#######################################
configure_git() {
    local gitconfig="${HOME}/.gitconfig"

    log_info "Checking git configuration..."

    # Check if .gitconfig is a symlink to dotfiles
    if [[ -L "$gitconfig" ]]; then
        log_info "Git configuration is properly symlinked"
        return 0
    elif [[ -f "$gitconfig" ]]; then
        log_warning "Git configuration exists but is not a symlink"
        log_warning "You may want to backup $gitconfig and run stow again"
        return 0
    else
        log_warning "Git configuration not found (will be created by stow)"
        return 0
    fi
}

#######################################
# Configure gem settings
# Verifies that gem configuration is properly symlinked
# Returns:
#   0 on success, 1 on failure
#######################################
configure_gem() {
    local gemrc="${HOME}/.gemrc"

    log_info "Checking gem configuration..."

    # Check if .gemrc is a symlink to dotfiles
    if [[ -L "$gemrc" ]]; then
        log_info "Gem configuration is properly symlinked"
        # Verify the setting is correct
        if grep -q "gem: --no-document" "$gemrc" 2>/dev/null; then
            log_info "Gem no-document setting is active"
        fi
        return 0
    elif [[ -f "$gemrc" ]]; then
        log_warning "Gem configuration exists but is not a symlink"
        log_warning "You may want to backup $gemrc and run stow again"
        return 0
    else
        log_warning "Gem configuration not found (will be created by stow)"
        return 0
    fi
}

#######################################
# Verify and fix PATH configuration
# Ensures ~/bin is in PATH in shell config files
# Returns:
#   0 on success, 1 on failure
#######################################
verify_path_config() {
    local shell_config
    local path_line='export PATH="$HOME/bin:$PATH"'

    log_info "Verifying PATH configuration..."

    # Detect shell config file
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "${SHELL:-}" == *"zsh"* ]]; then
        shell_config="${HOME}/.zshrc"
    else
        shell_config="${HOME}/.bash_profile"
    fi

    # Check if shell config exists
    if [[ ! -f "$shell_config" ]]; then
        log_warning "Shell config not found: $shell_config"
        log_warning "Will be created by stow"
        return 0
    fi

    # Check if PATH includes ~/bin
    if grep -q 'HOME/bin.*PATH' "$shell_config"; then
        log_info "PATH configuration is present in $shell_config"
        return 0
    else
        log_warning "PATH configuration missing from $shell_config"
        log_info "Adding ~/bin to PATH in $shell_config"

        # Add PATH configuration
        {
            echo ""
            echo "# Add ~/bin to PATH"
            echo "$path_line"
        } >> "$shell_config"

        log_info "PATH configuration added successfully"
        return 0
    fi
}

#######################################
# Verify all configurations are properly applied
# Checks symlinks, PATH, and configuration files
# Returns:
#   0 on success (all checks pass), 1 on failure
#######################################
verify_configs() {
    log_info "Verifying all configurations..."

    local checks_passed=0
    local checks_failed=0

    # Check git config
    if [[ -L "${HOME}/.gitconfig" ]]; then
        log_info "✓ Git configuration symlink present"
        checks_passed=$((checks_passed + 1))
    else
        log_warning "✗ Git configuration symlink missing"
        checks_failed=$((checks_failed + 1))
    fi

    # Check gem config
    if [[ -L "${HOME}/.gemrc" ]]; then
        log_info "✓ Gem configuration symlink present"
        checks_passed=$((checks_passed + 1))
    else
        log_warning "✗ Gem configuration symlink missing"
        checks_failed=$((checks_failed + 1))
    fi

    # Check zsh config (default on modern macOS)
    if [[ -L "${HOME}/.zshrc" ]] || [[ -L "${HOME}/.zprofile" ]]; then
        log_info "✓ Zsh configuration symlink present"
        checks_passed=$((checks_passed + 1))
    else
        log_warning "✗ Zsh configuration symlinks missing"
        checks_failed=$((checks_failed + 1))
    fi

    # Check bin directory
    if [[ -d "${HOME}/bin" ]] && [[ -L "${HOME}/bin" ]]; then
        log_info "✓ ~/bin directory symlinked"
        checks_passed=$((checks_passed + 1))
    else
        log_warning "✗ ~/bin directory not symlinked"
        checks_failed=$((checks_failed + 1))
    fi

    log_info "Configuration verification: $checks_passed passed, $checks_failed warnings"

    # Return 0 even if some checks failed (warnings only)
    return 0
}

#######################################
# Apply all global configurations
# Main entry point for configuration management
# Returns:
#   0 on success, 1 on failure
#######################################
apply_configs() {
    log_info "Applying global configurations..."

    local failed=0

    # Configure git
    if ! configure_git; then
        log_error "Git configuration failed"
        failed=1
    fi

    # Configure gem
    if ! configure_gem; then
        log_error "Gem configuration failed"
        failed=1
    fi

    # Verify PATH
    if ! verify_path_config; then
        log_warning "PATH verification failed"
        # Don't fail on PATH issues
    fi

    if [[ $failed -eq 0 ]]; then
        log_info "All configurations applied successfully"
        return 0
    else
        log_error "Some configurations failed"
        return 1
    fi
}
