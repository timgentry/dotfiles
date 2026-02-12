# Data Model: Dotfiles Setup

**Feature**: Dotfiles Setup Command
**Date**: 2026-02-12

This document defines the data structures and state management for the dotfiles setup system.

---

## 1. System State

### Installation State

Tracks whether dotfiles have been installed and setup status.

**State File Location**: `~/.dotfiles_state`

**State Schema**:
```json
{
  "installed": true,
  "installed_at": "2026-02-12T10:30:00Z",
  "last_updated": "2026-02-12T10:30:00Z",
  "version": "1.0.0",
  "dotfiles_path": "/Users/username/.dotfiles",
  "platform": "macos-arm64"
}
```

**State Transitions**:
- `not_installed` → `installing` → `installed` (first run)
- `installed` → `updating` → `installed` (subsequent runs)
- `installed` → `error` (setup failure)

**State Detection Logic**:
```bash
# Check if state file exists
if [[ -f ~/.dotfiles_state ]]; then
    # Parse state file
    state=$(jq -r '.installed' ~/.dotfiles_state)
    if [[ "$state" == "true" ]]; then
        mode="update"
    else
        mode="install"
    fi
else
    mode="install"
fi
```

---

## 2. Dotfiles Repository Structure

### Repository Entity

Represents the dotfiles repository on disk.

**Attributes**:
- `repo_url`: Git repository URL (e.g., `https://github.com/user/dotfiles.git`)
- `install_path`: Local installation path (default: `~/.dotfiles`)
- `branch`: Git branch to use (default: `main`)
- `commit_hash`: Current commit hash
- `remote_name`: Git remote name (default: `origin`)

**Example**:
```json
{
  "repo_url": "https://github.com/timgentry/dotfiles.git",
  "install_path": "/Users/tim/.dotfiles",
  "branch": "main",
  "commit_hash": "abc123def456",
  "remote_name": "origin"
}
```

---

## 3. Package Definitions

### Homebrew Package

Represents a package managed by Homebrew.

**Attributes**:
- `name`: Package name
- `type`: Package type (`formula`, `cask`, `tap`, `mas`)
- `version`: Installed version (optional)
- `installed`: Boolean - whether currently installed

**Example (Brewfile entry)**:
```ruby
tap "homebrew/bundle"
brew "git", version: "2.40.0"
brew "stow"
cask "visual-studio-code"
mas "Xcode", id: 497799835
```

**State Tracking**:
```bash
# Check if package is installed
brew list git &>/dev/null && echo "installed" || echo "not installed"

# Get installed version
brew list --versions git | awk '{print $2}'
```

---

## 4. Stow Package

### Stow Package Entity

Represents a dotfiles package managed by GNU Stow.

**Attributes**:
- `name`: Package name (directory name in dotfiles repo)
- `path`: Full path to package directory
- `stowed`: Boolean - whether currently stowed
- `files`: List of files in package
- `target`: Target directory (typically `~`)

**Example**:
```json
{
  "name": "bash",
  "path": "/Users/tim/.dotfiles/config/bash",
  "stowed": true,
  "files": [".bashrc", ".bash_profile"],
  "target": "/Users/tim"
}
```

**Stow State Detection**:
```bash
# Check if package is stowed
if stow -n -v bash 2>&1 | grep -q "is already stowed"; then
    echo "stowed"
else
    echo "not stowed"
fi
```

---

## 5. Configuration File

### Configuration Entity

Represents a configuration file or setting.

**Attributes**:
- `name`: Configuration name
- `type`: Configuration type (`file`, `symlink`, `setting`)
- `source_path`: Path in dotfiles repo
- `target_path`: Path in home directory
- `applied`: Boolean - whether configuration is applied

**Example - File Configuration**:
```json
{
  "name": "gitconfig",
  "type": "symlink",
  "source_path": "/Users/tim/.dotfiles/config/git/.gitconfig",
  "target_path": "/Users/tim/.gitconfig",
  "applied": true
}
```

**Example - Setting Configuration**:
```json
{
  "name": "gem_no_doc",
  "type": "setting",
  "source_path": "/Users/tim/.dotfiles/config/gem/.gemrc",
  "target_path": "/Users/tim/.gemrc",
  "applied": true
}
```

---

## 6. Script Entity

### Utility Script

Represents a utility script in the `bin/` directory.

**Attributes**:
- `name`: Script name
- `path`: Full path to script
- `in_path`: Boolean - whether accessible via PATH
- `executable`: Boolean - whether has execute permission

**Example**:
```json
{
  "name": "gh-open",
  "path": "/Users/tim/.dotfiles/bin/gh-open",
  "in_path": true,
  "executable": true
}
```

**PATH Detection**:
```bash
# Check if script is in PATH
command -v gh-open &>/dev/null && echo "in path" || echo "not in path"

# Check if executable
[[ -x /Users/tim/.dotfiles/bin/gh-open ]] && echo "executable" || echo "not executable"
```

---

## 7. Environment Configuration

### Shell Environment

Tracks shell environment configuration state.

**Attributes**:
- `shell_type`: Shell type (`bash`, `zsh`)
- `config_file`: Shell configuration file path
- `homebrew_configured`: Boolean - whether `brew shellenv` is sourced
- `bin_in_path`: Boolean - whether `~/bin` is in PATH

**Example**:
```json
{
  "shell_type": "zsh",
  "config_file": "/Users/tim/.zshrc",
  "homebrew_configured": true,
  "bin_in_path": true
}
```

**Detection Logic**:
```bash
# Detect shell
if [[ -n "$ZSH_VERSION" ]]; then
    shell_type="zsh"
    config_file="$HOME/.zshrc"
elif [[ -n "$BASH_VERSION" ]]; then
    shell_type="bash"
    config_file="$HOME/.bash_profile"
fi

# Check if Homebrew is in shell config
grep -q "brew shellenv" "$config_file" && homebrew_configured=true

# Check if ~/bin is in PATH
echo "$PATH" | grep -q "$HOME/bin" && bin_in_path=true
```

---

## 8. Platform Information

### Platform Entity

Represents the current system platform.

**Attributes**:
- `os`: Operating system (`macos`, `linux`)
- `arch`: Architecture (`arm64`, `x64`)
- `os_version`: OS version (e.g., `14.2.1` for macOS Sonoma)
- `platform_string`: Combined platform identifier (`macos-arm64`)

**Example**:
```json
{
  "os": "macos",
  "arch": "arm64",
  "os_version": "14.2.1",
  "platform_string": "macos-arm64"
}
```

**Detection Logic**:
```bash
# Detect OS
case "$(uname -s)" in
    Darwin*) os="macos" ;;
    Linux*)  os="linux" ;;
esac

# Detect architecture
case "$(uname -m)" in
    arm64|aarch64) arch="arm64" ;;
    x86_64|amd64)  arch="x64" ;;
esac

# Get OS version
if [[ "$os" == "macos" ]]; then
    os_version=$(sw_vers -productVersion)
fi

platform_string="${os}-${arch}"
```

---

## 9. Setup Log

### Log Entry

Represents a logged event during setup.

**Attributes**:
- `timestamp`: ISO 8601 timestamp
- `level`: Log level (`info`, `warn`, `error`)
- `message`: Log message
- `context`: Additional context (optional)

**Example**:
```json
{
  "timestamp": "2026-02-12T10:30:15Z",
  "level": "info",
  "message": "Installing Homebrew packages",
  "context": {
    "brewfile": "/Users/tim/.dotfiles/Brewfile",
    "packages_count": 15
  }
}
```

**Log File Location**: `~/.dotfiles/setup.log`

**Log Format** (JSON Lines):
```json
{"timestamp":"2026-02-12T10:30:00Z","level":"info","message":"Starting dotfiles setup"}
{"timestamp":"2026-02-12T10:30:05Z","level":"info","message":"Homebrew already installed"}
{"timestamp":"2026-02-12T10:30:10Z","level":"info","message":"Installing Brewfile packages"}
{"timestamp":"2026-02-12T10:30:45Z","level":"info","message":"Stowing package: bash"}
{"timestamp":"2026-02-12T10:31:00Z","level":"info","message":"Setup complete"}
```

---

## 10. Relationships

### Entity Relationships

```
Repository (1) ──┬── (many) Stow Packages
                 │
                 ├── (1) Brewfile
                 │    └── (many) Homebrew Packages
                 │
                 ├── (many) Configuration Files
                 │
                 └── (many) Utility Scripts

Installation State (1) ── (1) Repository

Environment (1) ── (1) Platform
              └── (1) Shell Configuration

Setup Log (many) ── (1) Installation State
```

---

## 11. State Persistence

### File Locations

**State Files**:
- Installation state: `~/.dotfiles_state` (JSON)
- Setup log: `~/.dotfiles/setup.log` (JSON Lines)
- Stow metadata: `~/.dotfiles/.stow-*` (Stow internal)

**Configuration Files** (in repo):
- Brewfile: `~/.dotfiles/Brewfile`
- Stow packages: `~/.dotfiles/config/<package>/`
- Utility scripts: `~/.dotfiles/bin/`

**Shell Configuration** (modified by setup):
- `~/.zshrc` or `~/.bash_profile` (Homebrew shellenv, PATH)

---

## 12. Validation Rules

### State Validation

**Installation State**:
- `installed` must be boolean
- `installed_at` and `last_updated` must be valid ISO 8601 timestamps
- `dotfiles_path` must be an absolute path
- `platform` must match pattern: `(macos|linux)-(arm64|x64)`

**Repository**:
- `install_path` must exist and be a git repository
- `branch` must exist in repository
- `repo_url` must be a valid Git URL

**Stow Package**:
- Package directory must exist in `~/.dotfiles/config/`
- Files in package must not conflict with existing files (unless stowed)

**Homebrew Package**:
- Package name must be valid Homebrew formula/cask name
- Type must be one of: `formula`, `cask`, `tap`, `mas`

---

## 13. Error States

### Error Conditions

**Repository Errors**:
- `clone_failed`: Git clone operation failed
- `pull_failed`: Git pull operation failed
- `invalid_repo`: Directory exists but is not a git repository

**Homebrew Errors**:
- `homebrew_install_failed`: Homebrew installation failed
- `brewfile_not_found`: Brewfile missing from repository
- `package_install_failed`: Individual package installation failed

**Stow Errors**:
- `stow_conflict`: File conflict prevents stowing
- `stow_not_found`: GNU Stow not installed
- `package_not_found`: Stow package directory doesn't exist

**Environment Errors**:
- `shell_config_not_found`: Can't locate shell configuration file
- `permission_denied`: Insufficient permissions for operation

---

**Status**: ✅ Data model complete
