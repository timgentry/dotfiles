#!/usr/bin/env bash
# Homebrew installation and management functions
# Handles Homebrew detection, installation, Brewfile processing, and shell environment setup

set -euo pipefail

#######################################
# Detect if Homebrew is installed and return its prefix path
# Outputs:
#   Homebrew prefix path to stdout
# Returns:
#   0 if found, 1 if not found
#######################################
detect_homebrew() {
    # Check if brew command is available
    if command -v brew &>/dev/null; then
        # Get the prefix from brew itself
        brew --prefix
        return 0
    fi

    # Check architecture-specific default locations
    local arch
    arch=$(uname -m)

    if [[ "$arch" == "arm64" ]]; then
        # Apple Silicon default location
        if [[ -x "/opt/homebrew/bin/brew" ]]; then
            echo "/opt/homebrew"
            return 0
        fi
    else
        # Intel default location
        if [[ -x "/usr/local/bin/brew" ]]; then
            echo "/usr/local"
            return 0
        fi
    fi

    return 1
}

#######################################
# Install Homebrew non-interactively
# Uses official Homebrew installation script
# Globals:
#   NONINTERACTIVE (optional)
# Outputs:
#   Installation progress to stdout
# Returns:
#   0 on success, 1 on failure
#######################################
install_homebrew() {
    log_info "Installing Homebrew..."

    # Use NONINTERACTIVE=1 to skip confirmation prompts
    if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        log_info "Homebrew installed successfully"
        return 0
    else
        log_error "Homebrew installation failed"
        return 1
    fi
}

#######################################
# Add Homebrew shell environment to shell configuration file
# Modifies ~/.zshrc or ~/.bash_profile to include 'brew shellenv'
# Arguments:
#   homebrew_prefix: Path to Homebrew installation
# Outputs:
#   Status messages to stdout
# Returns:
#   0 on success, 1 on failure
#######################################
configure_shell_env() {
    local homebrew_prefix="$1"
    local shell_config
    local shellenv_line

    # Detect shell and config file
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "${SHELL:-}" == *"zsh"* ]]; then
        shell_config="${HOME}/.zshrc"
    else
        shell_config="${HOME}/.bash_profile"
    fi

    # Create shell config if it doesn't exist
    touch "$shell_config"

    # Construct the shellenv line
    shellenv_line="eval \"\$(${homebrew_prefix}/bin/brew shellenv)\""

    # Check if already configured
    if grep -qF "brew shellenv" "$shell_config"; then
        log_info "Homebrew shell environment already configured in $shell_config"
        return 0
    fi

    # Add to shell config
    {
        echo ""
        echo "# Homebrew environment setup"
        echo "$shellenv_line"
    } >> "$shell_config"

    log_info "Added Homebrew shell environment to $shell_config"

    # Source it for current session
    eval "$($homebrew_prefix/bin/brew shellenv)"

    return 0
}

#######################################
# Install packages from Brewfile
# Arguments:
#   brewfile_path: Path to Brewfile
# Outputs:
#   Installation progress to stdout
# Returns:
#   0 on success, 1 on failure
#######################################
install_brewfile() {
    local brewfile_path="$1"

    if [[ ! -f "$brewfile_path" ]]; then
        log_error "Brewfile not found: $brewfile_path"
        return 1
    fi

    log_info "Installing packages from Brewfile: $brewfile_path"

    # Install with recommended flags:
    # --no-upgrade: Don't upgrade existing packages (faster, more predictable)
    # --verbose: Show detailed output
    if brew bundle install --file="$brewfile_path" --no-upgrade --verbose; then
        log_info "Brewfile packages installed successfully"
        return 0
    else
        log_error "Brewfile installation failed"
        return 1
    fi
}
