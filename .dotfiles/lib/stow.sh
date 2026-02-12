#!/usr/bin/env bash
# GNU Stow operations for dotfiles symlinking
# Handles stow package management, conflict detection and resolution

set -euo pipefail

#######################################
# Check if GNU Stow is installed
# Returns:
#   0 if installed, 1 if not
#######################################
check_stow_installed() {
    if command -v stow &>/dev/null; then
        return 0
    else
        log_error "GNU Stow is not installed"
        log_error "Please install stow via: brew install stow"
        return 1
    fi
}

#######################################
# Stow a single package
# Arguments:
#   package_name: Name of package directory to stow
#   target_dir: Target directory (typically ~)
# Outputs:
#   Stow operation details to stdout
# Returns:
#   0 on success, 1 on conflict or error
#######################################
stow_package() {
    local package_name="$1"
    local target_dir="${2:-$HOME}"
    local dotfiles_dir="${DOTFILES_DIR:-${HOME}/.dotfiles}"
    local package_path="${dotfiles_dir}/config/${package_name}"

    if [[ ! -d "$package_path" ]]; then
        log_error "Package directory not found: $package_path"
        return 1
    fi

    log_info "Stowing package: $package_name"

    # Change to config directory for stow operations
    cd "${dotfiles_dir}/config" || return 1

    # Try stowing with verbose output
    if stow -v -t "$target_dir" "$package_name" 2>&1 | tee -a "${HOME}/.dotfiles/setup.log"; then
        log_info "Successfully stowed package: $package_name"
        return 0
    else
        log_error "Failed to stow package: $package_name"
        # Try to handle conflicts
        handle_stow_conflicts "$package_name" "$target_dir"
        return 1
    fi
}

#######################################
# Stow all packages in config directory
# Globals:
#   DOTFILES_DIR (optional, defaults to ~/.dotfiles)
# Outputs:
#   Stow operation details to stdout
# Returns:
#   0 on success, non-zero on any failure
#######################################
stow_packages() {
    local dotfiles_dir="${DOTFILES_DIR:-${HOME}/.dotfiles}"
    local config_dir="${dotfiles_dir}/config"
    local target_dir="$HOME"
    local failed_packages=()

    if [[ ! -d "$config_dir" ]]; then
        log_error "Config directory not found: $config_dir"
        return 1
    fi

    log_info "Stowing all packages from: $config_dir"

    # Clean up broken symlinks in home directory before stowing
    log_info "Checking for broken symlinks..."
    local broken_count=0
    while IFS= read -r -d '' broken_link; do
        log_warning "Removing broken symlink: $broken_link"
        rm -f "$broken_link"
        broken_count=$((broken_count + 1))
    done < <(find "$target_dir" -maxdepth 1 -type l ! -exec test -e {} \; -print0 2>/dev/null)

    if [[ $broken_count -gt 0 ]]; then
        log_info "Removed $broken_count broken symlink(s)"
    else
        log_info "No broken symlinks found"
    fi

    # Also stow bin directory if it exists
    if [[ -d "${dotfiles_dir}/bin" ]]; then
        log_info "Stowing bin directory"
        cd "$dotfiles_dir" || return 1
        if ! stow -v -t "$target_dir" bin 2>&1 | tee -a "${HOME}/.dotfiles/setup.log"; then
            log_warning "Failed to stow bin directory"
            failed_packages+=("bin")
        fi
    fi

    # Iterate through config packages
    cd "$config_dir" || return 1

    # Determine if we're in update mode (state file exists)
    local restow_flag=""
    if [[ -f "${HOME}/.dotfiles_state" ]]; then
        # Use -R flag to restow (removes obsolete symlinks)
        restow_flag="-R"
        log_info "Update mode: using restow to clean obsolete symlinks"
    fi

    for package_dir in */; do
        # Remove trailing slash
        local package_name="${package_dir%/}"

        # In update mode, use stow -R for restow
        if [[ -n "$restow_flag" ]]; then
            log_info "Restowing package: $package_name"
            if stow -R -v -t "$target_dir" "$package_name" 2>&1 | tee -a "${HOME}/.dotfiles/setup.log"; then
                log_info "Successfully restowed package: $package_name"
                continue
            else
                failed_packages+=("$package_name")
            fi
        else
            if stow_package "$package_name" "$target_dir"; then
                continue
            else
                failed_packages+=("$package_name")
            fi
        fi
    done

    # Report results
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_error "Failed to stow packages: ${failed_packages[*]}"
        return 1
    fi

    log_info "All packages stowed successfully"
    return 0
}

#######################################
# Handle Stow conflicts by detecting and offering resolution
# Arguments:
#   package_name: Package with conflicts
#   target_dir: Target directory (optional, defaults to ~)
# Outputs:
#   Conflict details and resolution options
# Returns:
#   0 if resolved, 1 if unresolved
#######################################
handle_stow_conflicts() {
    local package_name="$1"
    local target_dir="${2:-$HOME}"
    local dotfiles_dir="${DOTFILES_DIR:-${HOME}/.dotfiles}"

    log_warning "Detected conflicts for package: $package_name"

    # Run stow in dry-run mode to see what conflicts exist
    cd "${dotfiles_dir}/config" || return 1

    local conflicts
    conflicts=$(stow -n -v "$package_name" 2>&1 | grep -i "conflict" || true)

    if [[ -n "$conflicts" ]]; then
        log_warning "Conflicts detected:"
        echo "$conflicts"

        # In interactive mode, offer to backup conflicting files
        if [[ -z "${NONINTERACTIVE:-}" ]]; then
            if confirm "Backup existing files and retry stow?"; then
                # Create backup directory
                local backup_dir="${HOME}/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
                mkdir -p "$backup_dir"

                # Extract conflicting file paths and backup
                while IFS= read -r line; do
                    if [[ "$line" =~ "existing target is" ]]; then
                        local file_path="${line##*: }"
                        if [[ -f "$file_path" ]] || [[ -L "$file_path" ]]; then
                            log_info "Backing up: $file_path"
                            mv "$file_path" "$backup_dir/"
                        fi
                    fi
                done <<< "$conflicts"

                # Retry stow
                if stow -v -t "$target_dir" "$package_name"; then
                    log_info "Successfully stowed after backing up conflicts"
                    log_info "Backups saved to: $backup_dir"
                    return 0
                fi
            fi
        fi
    fi

    return 1
}
