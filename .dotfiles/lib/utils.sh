#!/usr/bin/env bash
# Utility functions for dotfiles setup
# Contains logging, platform detection, confirmation prompts, and dependency checks

set -euo pipefail

# Colors for terminal output
readonly COLOR_RESET='\033[0m'
readonly COLOR_INFO='\033[0;36m'    # Cyan
readonly COLOR_SUCCESS='\033[0;32m' # Green
readonly COLOR_WARNING='\033[0;33m' # Yellow
readonly COLOR_ERROR='\033[0;31m'   # Red

# Log file location
readonly LOG_FILE="${HOME}/.dotfiles/setup.log"

#######################################
# Log informational message to stdout and log file
# Globals:
#   LOG_FILE
# Arguments:
#   Message to log
# Outputs:
#   Writes to stdout and log file
#######################################
log_info() {
    local message="$1"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Output to terminal with color
    echo -e "${COLOR_INFO}=>${COLOR_RESET} ${message}"

    # Output to log file in JSON format
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "{\"timestamp\":\"${timestamp}\",\"level\":\"info\",\"message\":\"${message}\"}" >> "$LOG_FILE"
}

#######################################
# Log error message to stderr and log file
# Globals:
#   LOG_FILE
# Arguments:
#   Error message to log
# Outputs:
#   Writes to stderr and log file
#######################################
log_error() {
    local message="$1"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Output to terminal with color
    echo -e "${COLOR_ERROR}ERROR:${COLOR_RESET} ${message}" >&2

    # Output to log file in JSON format
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "{\"timestamp\":\"${timestamp}\",\"level\":\"error\",\"message\":\"${message}\"}" >> "$LOG_FILE"
}

#######################################
# Log warning message to stdout and log file
# Globals:
#   LOG_FILE
# Arguments:
#   Warning message to log
# Outputs:
#   Writes to stdout and log file
#######################################
log_warning() {
    local message="$1"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Output to terminal with color
    echo -e "${COLOR_WARNING}Warning:${COLOR_RESET} ${message}"

    # Output to log file in JSON format
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "{\"timestamp\":\"${timestamp}\",\"level\":\"warn\",\"message\":\"${message}\"}" >> "$LOG_FILE"
}

#######################################
# Detect current platform and architecture
# Returns platform string in format: (macos|linux)-(arm64|x64)
# Outputs:
#   Platform string to stdout
# Returns:
#   0 on success
#######################################
get_platform() {
    local os arch platform_string

    # Detect OS
    case "$(uname -s)" in
        Darwin*) os="macos" ;;
        Linux*)  os="linux" ;;
        *)
            log_error "Unsupported operating system: $(uname -s)"
            return 1
            ;;
    esac

    # Detect architecture
    case "$(uname -m)" in
        arm64|aarch64) arch="arm64" ;;
        x86_64|amd64)  arch="x64" ;;
        *)
            log_error "Unsupported architecture: $(uname -m)"
            return 1
            ;;
    esac

    platform_string="${os}-${arch}"
    echo "$platform_string"
    return 0
}

#######################################
# Prompt user for yes/no confirmation
# Skips prompt if NONINTERACTIVE environment variable is set
# Arguments:
#   Prompt message (question to ask user)
# Outputs:
#   Writes prompt to stdout
# Returns:
#   0 if user confirms (y/yes), 1 if user declines (n/no)
#######################################
confirm() {
    local prompt="${1:-Continue?}"
    local response

    # Skip in non-interactive mode (CI/CD)
    if [[ -n "${NONINTERACTIVE:-}" ]]; then
        log_info "Non-interactive mode: auto-confirming"
        return 0
    fi

    while true; do
        # Read from /dev/tty for robustness
        read -r -p "${prompt} [y/N] " response < /dev/tty
        case "${response}" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo]|"")
                return 1
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}

#######################################
# Verify that a required command is available
# Exits entire script if command not found
# Arguments:
#   Command name to check
# Outputs:
#   Error message to stderr if command not found
# Returns:
#   0 if found, exits script with code 2 if not found
#######################################
need_cmd() {
    local cmd="$1"

    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command not found: $cmd"
        log_error "Please install $cmd and try again"
        exit 2
    fi
}
