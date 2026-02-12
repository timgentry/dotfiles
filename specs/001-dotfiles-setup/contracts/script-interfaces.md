# Script Interface Contracts

**Feature**: Dotfiles Setup Command
**Date**: 2026-02-12

This document defines the interfaces (function signatures, inputs, outputs, exit codes) for all scripts in the dotfiles setup system.

---

## 1. Remote Installation Script

### `install.sh`

**Purpose**: Bootstrap script executed via `curl | bash` that clones repository and initiates setup.

**Execution**:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/user/dotfiles/main/install.sh)
```

**Environment Variables** (optional inputs):
- `DOTFILES_REPO`: Repository URL (default: auto-detected from script source)
- `DOTFILES_DIR`: Installation directory (default: `~/.dotfiles`)
- `DOTFILES_BRANCH`: Git branch to clone (default: `main`)
- `NONINTERACTIVE`: Skip confirmation prompts if set (default: unset)

**Behavior**:
1. Validates dependencies (git, curl, bash)
2. Detects platform (macOS vs Linux, architecture)
3. On first install: prompts for confirmation (unless `NONINTERACTIVE`)
4. Clones repository to `$DOTFILES_DIR`
5. Executes `$DOTFILES_DIR/.dotfiles/setup.sh`

**Exit Codes**:
- `0`: Success
- `1`: Dependency missing (git, curl)
- `2`: Clone failed
- `3`: Setup script failed
- `4`: User cancelled installation

**Output**:
- Progress messages to stdout
- Errors to stderr
- Final status: "Installation complete!" or error message

---

## 2. Main Setup Script

### `.dotfiles/setup.sh`

**Purpose**: Main orchestrator that coordinates Homebrew, Stow, and configuration.

**Execution**:
```bash
~/.dotfiles/.dotfiles/setup.sh
```

**Environment Variables** (optional inputs):
- `NONINTERACTIVE`: Skip confirmation prompts if set
- `SKIP_HOMEBREW`: Skip Homebrew installation if set
- `SKIP_STOW`: Skip Stow operations if set
- `BREWFILE`: Path to Brewfile (default: `$DOTFILES_DIR/Brewfile`)

**Behavior**:
1. Sources all library files from `lib/`
2. Detects first run vs update (via state file)
3. On first run: requests user confirmation
4. Calls `homebrew_setup` from `lib/homebrew.sh`
5. Calls `stow_packages` from `lib/stow.sh`
6. Calls `apply_configs` from `lib/config.sh`
7. Updates state file
8. Logs all operations

**Exit Codes**:
- `0`: Success
- `1`: General error
- `2`: Homebrew setup failed
- `3`: Stow operation failed
- `4`: Configuration failed

**Output**:
- Progress to stdout (with colors)
- Errors to stderr
- Detailed log to `~/.dotfiles/setup.log`

---

## 3. Homebrew Library

### `lib/homebrew.sh`

#### Function: `detect_homebrew`

**Purpose**: Detects if Homebrew is installed and returns prefix path.

**Signature**:
```bash
detect_homebrew() -> string
```

**Returns**:
- stdout: Homebrew prefix path (e.g., `/opt/homebrew`)
- exit code: `0` if found, `1` if not found

**Example**:
```bash
if HOMEBREW_PREFIX=$(detect_homebrew); then
    echo "Found at: $HOMEBREW_PREFIX"
fi
```

#### Function: `install_homebrew`

**Purpose**: Installs Homebrew non-interactively.

**Signature**:
```bash
install_homebrew() -> void
```

**Environment Variables**:
- Uses `NONINTERACTIVE=1` for installation

**Returns**:
- exit code: `0` on success, `1` on failure

**Side Effects**:
- Installs Homebrew to `/opt/homebrew` or `/usr/local`
- May require sudo password

#### Function: `configure_shell_env`

**Purpose**: Adds `brew shellenv` to shell configuration file.

**Signature**:
```bash
configure_shell_env(homebrew_prefix: string) -> void
```

**Parameters**:
- `homebrew_prefix`: Path to Homebrew installation

**Returns**:
- exit code: `0` on success, `1` on failure

**Side Effects**:
- Modifies `~/.zshrc` or `~/.bash_profile`
- Adds eval line if not already present

#### Function: `install_brewfile`

**Purpose**: Installs packages from Brewfile.

**Signature**:
```bash
install_brewfile(brewfile_path: string) -> void
```

**Parameters**:
- `brewfile_path`: Path to Brewfile

**Returns**:
- exit code: `0` on success, `1` on failure

**Options Used**:
- `--no-upgrade`: Don't upgrade existing packages
- `--verbose`: Show detailed output

---

## 4. Stow Library

### `lib/stow.sh`

#### Function: `check_stow_installed`

**Purpose**: Verifies GNU Stow is available.

**Signature**:
```bash
check_stow_installed() -> void
```

**Returns**:
- exit code: `0` if installed, `1` if not

#### Function: `stow_package`

**Purpose**: Stows a single package.

**Signature**:
```bash
stow_package(package_name: string, target_dir: string) -> void
```

**Parameters**:
- `package_name`: Name of package directory
- `target_dir`: Target directory (typically `~`)

**Returns**:
- exit code: `0` on success, `1` on conflict or error

**Options Used**:
- `-v`: Verbose output
- `-t`: Target directory

#### Function: `stow_packages`

**Purpose**: Stows all packages in config directory.

**Signature**:
```bash
stow_packages() -> void
```

**Returns**:
- exit code: `0` on success, non-zero on any failure

**Behavior**:
- Iterates through `config/*/` directories
- Calls `stow_package` for each
- Continues on individual failures, reports at end

#### Function: `handle_stow_conflicts`

**Purpose**: Detects and helps resolve Stow conflicts.

**Signature**:
```bash
handle_stow_conflicts(package_name: string) -> void
```

**Parameters**:
- `package_name`: Package with conflicts

**Returns**:
- exit code: `0` if resolved, `1` if unresolved

**Behavior**:
- Runs `stow -n` to detect conflicts
- Offers to backup conflicting files
- Retries stow after backup

---

## 5. Configuration Library

### `lib/config.sh`

#### Function: `apply_configs`

**Purpose**: Applies global configurations (gem, git, etc.).

**Signature**:
```bash
apply_configs() -> void
```

**Returns**:
- exit code: `0` on success, `1` on failure

**Behavior**:
- Verifies config files are stowed
- Applies any additional settings not handled by Stow

#### Function: `configure_git`

**Purpose**: Applies global git configuration.

**Signature**:
```bash
configure_git() -> void
```

**Returns**:
- exit code: `0` on success, `1` on failure

**Side Effects**:
- May set global git config values

#### Function: `configure_gem`

**Purpose**: Ensures gem configuration is applied.

**Signature**:
```bash
configure_gem() -> void
```

**Returns**:
- exit code: `0` on success, `1` on failure

**Verification**:
- Checks that `~/.gemrc` is a symlink to dotfiles

---

## 6. State Library

### `lib/state.sh`

#### Function: `is_first_run`

**Purpose**: Determines if this is the first installation.

**Signature**:
```bash
is_first_run() -> boolean
```

**Returns**:
- exit code: `0` if first run, `1` if update

**Detection**:
- Checks for `~/.dotfiles_state` file
- Returns true if file doesn't exist or `installed: false`

#### Function: `save_state`

**Purpose**: Persists installation state to file.

**Signature**:
```bash
save_state() -> void
```

**Returns**:
- exit code: `0` on success, `1` on failure

**Side Effects**:
- Creates/updates `~/.dotfiles_state` with JSON data

#### Function: `get_state`

**Purpose**: Reads current installation state.

**Signature**:
```bash
get_state(key: string) -> string
```

**Parameters**:
- `key`: State key to retrieve (e.g., `installed_at`)

**Returns**:
- stdout: Value for key
- exit code: `0` on success, `1` if key not found

---

## 7. Utilities Library

### `lib/utils.sh`

#### Function: `log_info`

**Purpose**: Logs informational message.

**Signature**:
```bash
log_info(message: string) -> void
```

**Parameters**:
- `message`: Message to log

**Output**:
- stdout: Colored message with `=>` prefix
- Appends to `setup.log` with timestamp

#### Function: `log_error`

**Purpose**: Logs error message.

**Signature**:
```bash
log_error(message: string) -> void
```

**Parameters**:
- `message`: Error message

**Output**:
- stderr: Colored error message with `ERROR:` prefix
- Appends to `setup.log` with level `error`

#### Function: `log_warning`

**Purpose**: Logs warning message.

**Signature**:
```bash
log_warning(message: string) -> void
```

**Parameters**:
- `message`: Warning message

**Output**:
- stdout: Colored warning with `Warning:` prefix
- Appends to `setup.log` with level `warn`

#### Function: `confirm`

**Purpose**: Prompts user for yes/no confirmation.

**Signature**:
```bash
confirm(prompt: string) -> boolean
```

**Parameters**:
- `prompt`: Question to ask user

**Returns**:
- exit code: `0` if user confirms (y/yes), `1` if user declines (n/no)

**Behavior**:
- If `NONINTERACTIVE` is set, returns `0` (auto-confirm)
- Reads from `/dev/tty` for robustness
- Loops until valid response

#### Function: `get_platform`

**Purpose**: Detects current platform.

**Signature**:
```bash
get_platform() -> string
```

**Returns**:
- stdout: Platform string (e.g., `macos-arm64`)
- exit code: `0` on success

**Detection**:
- Uses `uname -s` for OS
- Uses `uname -m` for architecture
- Normalizes to `(macos|linux)-(arm64|x64)`

#### Function: `need_cmd`

**Purpose**: Verifies required command is available.

**Signature**:
```bash
need_cmd(command: string) -> void
```

**Parameters**:
- `command`: Command name to check

**Returns**:
- exit code: `0` if found, exits script with error if not found

**Behavior**:
- Uses `command -v` for detection
- Exits entire script on failure (with error message)

---

## 8. Utility Scripts

### `bin/gh-open`

**Purpose**: Opens current git branch in browser on GitHub.

**Execution**:
```bash
gh-open
```

**Requirements**:
- Must be in a git repository
- Repository must have GitHub remote named `origin`

**Behavior**:
1. Gets origin fetch URL via `git remote -v`
2. Converts git@ URL to https:// URL
3. Gets current branch via `git branch --show-current`
4. Constructs URL: `https://github.com/user/repo/tree/branch`
5. Opens in default browser (macOS: `open`, Linux: `xdg-open`)

**Exit Codes**:
- `0`: Success (browser opened)
- `1`: Not a git repository
- `2`: No origin remote found
- `3`: No browser command available

**Output**:
- If no browser: prints URL to stdout
- Errors to stderr

---

## 9. Common Exit Code Conventions

All scripts follow these conventions:

- `0`: Success
- `1`: General error / failure
- `2`: Missing dependency or prerequisite
- `3`: Operation failed (e.g., install, clone, stow)
- `4`: User cancelled operation
- `5`: Configuration error

---

## 10. Logging Contract

### Log Format

All logs written to `~/.dotfiles/setup.log` use JSON Lines format:

```json
{"timestamp":"2026-02-12T10:30:00Z","level":"info","message":"Starting setup"}
{"timestamp":"2026-02-12T10:30:05Z","level":"error","message":"Homebrew install failed","context":{"exit_code":1}}
```

### Log Levels

- `info`: Normal operational messages
- `warn`: Warning conditions (non-fatal)
- `error`: Error conditions (may be fatal)

### Required Fields

- `timestamp`: ISO 8601 format
- `level`: One of `info`, `warn`, `error`
- `message`: Human-readable message
- `context`: Optional object with additional data

---

## 11. Environment Variable Contract

### Standard Variables

**Input Variables** (optional, set by user):
- `DOTFILES_REPO`: Repository URL
- `DOTFILES_DIR`: Installation directory
- `DOTFILES_BRANCH`: Git branch
- `NONINTERACTIVE`: Skip prompts (any value)
- `SKIP_HOMEBREW`: Skip Homebrew installation
- `SKIP_STOW`: Skip Stow operations
- `BREWFILE`: Custom Brewfile path

**Internal Variables** (set by scripts):
- `HOMEBREW_PREFIX`: Homebrew installation path
- `PLATFORM`: Detected platform string
- `STATE_FILE`: Path to state file

### Variable Precedence

1. Explicitly set environment variables (highest)
2. Default values in scripts
3. Auto-detected values (lowest)

---

**Status**: ✅ Script interfaces defined
