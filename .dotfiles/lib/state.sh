#!/usr/bin/env bash
# State management for dotfiles installation
# Tracks first run vs update, persists installation state

set -euo pipefail

# State file location
readonly STATE_FILE="${HOME}/.dotfiles_state"

#######################################
# Determine if this is the first installation
# Checks for existence of state file and installed flag
# Returns:
#   0 if first run, 1 if update
#######################################
is_first_run() {
    if [[ ! -f "$STATE_FILE" ]]; then
        # State file doesn't exist - first run
        return 0
    fi

    # Check if jq is available for JSON parsing
    if command -v jq &>/dev/null; then
        local installed
        installed=$(jq -r '.installed' "$STATE_FILE" 2>/dev/null || echo "false")
        if [[ "$installed" == "true" ]]; then
            # Already installed - update run
            return 1
        fi
    fi

    # If we can't parse the file or installed is false, treat as first run
    return 0
}

#######################################
# Save installation state to state file
# Creates/updates state file with installation metadata
# Globals:
#   STATE_FILE
#   DOTFILES_DIR (optional, defaults to ~/.dotfiles)
# Outputs:
#   Writes JSON state file
# Returns:
#   0 on success, 1 on failure
#######################################
save_state() {
    local dotfiles_dir="${DOTFILES_DIR:-${HOME}/.dotfiles}"
    local timestamp platform version
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    version="1.0.0"

    # Get platform info
    if command -v get_platform &>/dev/null; then
        platform=$(get_platform)
    else
        platform="unknown"
    fi

    # Check if this is first install or update
    local installed_at
    if [[ -f "$STATE_FILE" ]] && command -v jq &>/dev/null; then
        installed_at=$(jq -r '.installed_at' "$STATE_FILE" 2>/dev/null || echo "$timestamp")
    else
        installed_at="$timestamp"
    fi

    # Create state JSON
    local state_json
    state_json=$(cat <<EOF
{
  "installed": true,
  "installed_at": "${installed_at}",
  "last_updated": "${timestamp}",
  "version": "${version}",
  "dotfiles_path": "${dotfiles_dir}",
  "platform": "${platform}"
}
EOF
)

    # Write to state file
    if echo "$state_json" > "$STATE_FILE"; then
        return 0
    else
        log_error "Failed to write state file: $STATE_FILE"
        return 1
    fi
}

#######################################
# Get value for a specific key from state file
# Arguments:
#   Key to retrieve (e.g., "installed_at", "platform")
# Outputs:
#   Value for key to stdout
# Returns:
#   0 on success, 1 if key not found or jq unavailable
#######################################
get_state() {
    local key="$1"

    if [[ ! -f "$STATE_FILE" ]]; then
        return 1
    fi

    if ! command -v jq &>/dev/null; then
        log_warning "jq not available, cannot parse state file"
        return 1
    fi

    local value
    value=$(jq -r ".${key}" "$STATE_FILE" 2>/dev/null)

    if [[ -n "$value" && "$value" != "null" ]]; then
        echo "$value"
        return 0
    fi

    return 1
}
