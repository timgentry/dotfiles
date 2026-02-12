# Research: Dotfiles Setup Implementation

**Feature**: Dotfiles Setup Command
**Date**: 2026-02-12
**Status**: Complete

This document consolidates research findings for implementing the dotfiles setup system using GNU Stow, Homebrew, and remote installation patterns.

---

## 1. GNU Stow for Dotfiles Management

### Decision: Use GNU Stow for Symlinking

**Rationale**: GNU Stow provides a clean, declarative way to manage symlinks from a dotfiles repository to the home directory. It's idempotent by default and widely adopted in the dotfiles community.

**How Stow Works**:
- Creates symlinks from target directory (typically `~`) back to files in the stow directory
- Uses "tree folding" optimization - creates directory symlinks when possible, unfolds when needed
- Two-phase algorithm: scans for conflicts first, then makes changes (atomic-like behavior)

### Directory Structure Pattern

**Recommended structure** (each subdirectory is a "package"):
```
~/.dotfiles/
├── bash/
│   ├── .bashrc
│   └── .bash_profile
├── git/
│   └── .gitconfig
├── gem/
│   └── .gemrc
└── bin/          # Utility scripts
    └── gh-open
```

**Key principle**: Directory structure inside each package must match the target structure in home directory.

### Conflict Handling

Stow detects conflicts before making changes. Resolution strategies:

1. **Adopt existing files**: `stow --adopt bash` - moves existing files into repository
2. **Manual backup**: `mv ~/.bashrc ~/.bashrc.backup && stow bash`
3. **Override**: `stow --override='.*' bash` - forces overwrite (use with caution)

### Idempotency

Stow operations are inherently idempotent:
- Running `stow package` multiple times is safe
- If symlink already points to correct location, no conflict occurs
- Use `stow -R package` (restow) to clean up obsolete symlinks after updates

### Essential Commands

```bash
# Stow a package
cd ~/.dotfiles && stow bash

# Stow all packages
stow */

# Restow (unstow then stow - cleans up obsolete links)
stow -R bash

# Dry run to preview changes
stow -nv bash

# Unstow a package
stow -D bash
```

### Integration Pattern

```bash
# Install GNU Stow via Homebrew
brew install stow

# Stow packages from dotfiles repo
cd ~/.dotfiles
for package in bash git gem bin; do
    stow -v "$package"
done
```

**Alternatives considered**: Manual symlinking scripts, rcm, yadm
**Why Stow chosen**: Simpler, more declarative, better conflict detection, widely supported

---

## 2. Homebrew Installation and Brewfile Management

### Decision: Use Official Homebrew Installation Method

**Rationale**: The official Homebrew install script is battle-tested, handles all edge cases (permissions, architecture detection, path setup), and is the community standard.

### Detection Pattern

```bash
# Recommended: Use command -v (POSIX-compliant)
if command -v brew &>/dev/null; then
    echo "Homebrew already installed"
else
    echo "Need to install Homebrew"
fi

# Architecture-aware path detection
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"  # Apple Silicon
else
    HOMEBREW_PREFIX="/usr/local"     # Intel
fi
```

### Non-Interactive Installation

```bash
# Use NONINTERACTIVE=1 to skip confirmation prompts
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Note**: Still requires sudo password if permissions need adjustment.

### Brewfile Pattern

**Create Brewfile**:
```ruby
# Taps
tap "homebrew/bundle"

# CLI tools
brew "git"
brew "stow"
brew "zsh"
brew "fzf"

# GUI applications
cask "visual-studio-code"
cask "iterm2"
```

**Install from Brewfile** (idempotent by default):
```bash
# Install packages listed in Brewfile
brew bundle install --file=~/.dotfiles/Brewfile

# Recommended flags for setup scripts:
brew bundle install --file=~/Brewfile --no-upgrade --verbose
```

**Key flags**:
- `--no-upgrade`: Don't upgrade existing packages (faster, more predictable)
- `--verbose`: Show detailed output
- `--cleanup`: Remove packages not in Brewfile (destructive - use carefully)

### Environment Configuration

After installing Homebrew, configure shell environment:

```bash
# Add to ~/.zshrc or ~/.bash_profile
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
# OR
eval "$(/usr/local/bin/brew shellenv)"      # Intel
```

### Idempotency

`brew bundle install` is idempotent:
- Skips already-installed packages
- Safe to run multiple times
- Use `brew bundle check` to verify current state

**Alternatives considered**: MacPorts, direct dmg downloads, manual compilation
**Why Homebrew chosen**: De facto standard for macOS, excellent Brewfile support, large package repository

---

## 3. Remote Installation Script Pattern (curl | bash)

### Decision: Two-Stage Bootstrap Approach

**Rationale**: Follow industry best practices from Homebrew, rustup, and other popular installers. Separates concerns: remote script handles bootstrapping, local script handles setup.

### Architecture

**Stage 1**: Remote bootstrap script (`install.sh` - curl | bash entry point)
- Validates dependencies (git, curl)
- Detects platform/architecture
- Clones dotfiles repository
- Executes local setup script

**Stage 2**: Local setup script (`~/.dotfiles/setup.sh`)
- Installs Homebrew if needed
- Processes Brewfile
- Runs Stow to symlink dotfiles
- Configures global settings

### Security Best Practices

**Essential curl flags**:
```bash
curl -fsSL https://example.com/install.sh | bash
```
- `-f`: Fail on HTTP errors
- `-s`: Silent mode (no progress bar)
- `-S`: Show errors even in silent mode
- `-L`: Follow redirects

**For maximum security** (like rustup):
```bash
curl -fsSL --proto '=https' --tlsv1.2 https://example.com/install.sh | bash
```

**Script structure** (prevents partial execution):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Define ALL functions first
main() {
    check_deps
    clone_repo
    run_setup
}

check_deps() { ... }
clone_repo() { ... }
run_setup() { ... }

# Only call main at the very end
main "$@"
```

**Why this structure**: If network connection drops mid-download, the `main` function never executes, preventing partial script execution.

### First Run Detection

**Flag-based state tracking**:
```bash
STATE_FILE="${HOME}/.dotfiles_installed"

if [[ ! -f "${STATE_FILE}" ]]; then
    # First run - show confirmation prompt
    confirm_installation
    perform_setup
    touch "${STATE_FILE}"
else
    # Subsequent run - skip confirmation
    perform_update
fi
```

**Alternative**: Check for installation directory existence
```bash
if [[ ! -d "${HOME}/.dotfiles" ]]; then
    # First run
else
    # Update
fi
```

### User Confirmation Pattern

```bash
confirm() {
    # Skip in non-interactive mode (CI/CD)
    if [[ -n "${NONINTERACTIVE:-}" ]]; then
        return 0
    fi

    local prompt="${1:-Continue?}"
    local response

    while true; do
        read -r -p "${prompt} [y/N] " response < /dev/tty
        case "${response}" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]|"")  return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}
```

### Error Handling and Rollback

**Strict mode**:
```bash
set -euo pipefail
# -e: Exit on error
# -u: Error on undefined variables
# -o pipefail: Fail if any command in pipe fails
```

**Cleanup trap**:
```bash
cleanup() {
    local exit_code=$?
    rm -rf "${TEMP_DIR}"
    exit "${exit_code}"
}
trap cleanup EXIT INT TERM
```

**Rollback stack**:
```bash
declare -a ROLLBACK_COMMANDS=()

add_rollback() {
    ROLLBACK_COMMANDS+=("$1")
}

rollback() {
    for (( idx=${#ROLLBACK_COMMANDS[@]}-1 ; idx>=0 ; idx-- )); do
        eval "${ROLLBACK_COMMANDS[idx]}" || true
    done
}
trap rollback ERR
```

### Clone and Execute Pattern

```bash
clone_and_setup() {
    local repo_url="https://github.com/user/dotfiles.git"
    local install_dir="${HOME}/.dotfiles"

    # Clone to temp location first
    local temp_dir=$(mktemp -d)

    if git clone --depth 1 "${repo_url}" "${temp_dir}/dotfiles"; then
        # Move to final location
        mv "${temp_dir}/dotfiles" "${install_dir}"

        # Execute setup
        cd "${install_dir}"
        chmod +x ./setup.sh
        ./setup.sh
    else
        rm -rf "${temp_dir}"
        return 1
    fi
}
```

**Alternatives considered**: Download tarball, use installer binaries, multi-file installer
**Why clone+execute chosen**: Simplest for dotfiles, enables git-based updates, follows Homebrew pattern

---

## 4. Implementation Decisions Summary

### Repository Structure

```
dotfiles/
├── install.sh           # Remote bootstrap (curl | bash entry point)
├── .dotfiles/
│   ├── setup.sh         # Main setup orchestrator
│   ├── lib/
│   │   ├── homebrew.sh  # Homebrew installation/Brewfile
│   │   ├── stow.sh      # Stow operations
│   │   ├── config.sh    # Global config management
│   │   ├── utils.sh     # Logging, confirmation, etc.
│   │   └── state.sh     # First run detection
│   ├── Brewfile         # Package definitions
│   └── config/          # Config files to stow
│       ├── bash/
│       ├── git/
│       └── gem/
└── bin/
    └── gh-open          # Demo utility script
```

### Installation Flow

1. User runs: `bash <(curl -fsSL https://example.com/install.sh)`
2. `install.sh` validates dependencies, clones repo to `~/.dotfiles`
3. `setup.sh` checks for first run (via state file)
4. On first run: prompts for confirmation
5. Installs Homebrew if not present
6. Configures shell environment (`brew shellenv`)
7. Installs packages via `brew bundle install`
8. Stows dotfile packages to home directory
9. Applies global configurations (gem, git, etc.)
10. Marks installation complete (creates state file)

### Idempotency Strategy

- **Homebrew**: `brew bundle install` is idempotent by default
- **Stow**: Symlink operations are idempotent (no-op if already linked)
- **Config files**: Check before modifying (grep/sed patterns)
- **State tracking**: Flag file for first-run detection
- **Updates**: `git pull && stow -R *` safely updates everything

### gh-open Script Implementation

Based on the provided alias, create `bin/gh-open`:

```bash
#!/usr/bin/env bash
# Open current git branch in browser on GitHub

set -euo pipefail

# Get remote URL
remote_url=$(git remote -v | grep -m 1 "origin.*fetch" | awk '{print $2}')

# Convert git@github.com:user/repo.git -> https://github.com/user/repo
remote_url=$(echo "$remote_url" | sed -E 's|git@github.com:(.*).git|https://github.com/\1|')
remote_url=$(echo "$remote_url" | sed -E 's|https://github.com/(.*).git|https://github.com/\1|')

# Append current branch
current_branch=$(git branch --show-current)
branch_url="${remote_url}/tree/${current_branch}"

# Open in browser
if command -v open &>/dev/null; then
    open "$branch_url"  # macOS
elif command -v xdg-open &>/dev/null; then
    xdg-open "$branch_url"  # Linux
else
    echo "$branch_url"
fi
```

This demonstrates that `bin/` scripts are in PATH after setup completes.

---

## 5. Technology Choices

| Component | Choice | Alternative Considered | Rationale |
|-----------|--------|----------------------|-----------|
| Symlink Manager | GNU Stow | Manual scripts, rcm, yadm | Declarative, idempotent, widely adopted |
| Package Manager | Homebrew | MacPorts, direct downloads | Industry standard, excellent Brewfile support |
| Install Pattern | curl \| bash | Download script first, installer binary | Follows Homebrew pattern, simplest for shell |
| Shell | Bash | Zsh, Fish | Maximum compatibility, macOS includes Bash |
| Testing Framework | bats-core | shunit2, roundup | Best maintained, good macOS support |
| State Tracking | Flag file | Git tags, database | Simplest, no dependencies |

---

## 6. Key Implementation Notes

### PATH Configuration

After stowing `bin/`, scripts are accessible if `~/bin` is in PATH. Add to shell config:

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$HOME/bin:$PATH"
```

Or use a more robust pattern:
```bash
if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi
```

### Global Configuration Examples

**Gem configuration** (`config/gem/.gemrc`):
```yaml
gem: --no-document
install: --no-document
update: --no-document
```

**Git configuration** (`config/git/.gitconfig`):
```ini
[user]
    name = User Name
    email = user@example.com
[core]
    autocrlf = false
[init]
    defaultBranch = main
```

### Testing Strategy

- **Unit tests** (bats-core): Test individual functions in lib/*.sh
- **Integration tests**: Full installation on clean macOS VM
- **Idempotency tests**: Run setup twice, verify no errors
- **Update tests**: Modify repo, re-run, verify changes applied

---

## References

### GNU Stow
- [Using GNU Stow to manage your dotfiles](https://tamerlan.dev/how-i-manage-my-dotfiles-using-gnu-stow/)
- [GNU Stow Manual - Managing Conflicts](https://www.gnu.org/software/stow/manual/html_node/Conflicts.html)
- [System Crafters - GNU Stow Tutorial](https://systemcrafters.net/managing-your-dotfiles/using-gnu-stow/)

### Homebrew
- [Homebrew Installation Documentation](https://docs.brew.sh/Installation)
- [Homebrew Bundle and Brewfile](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
- [Non-Interactive Installation Discussion](https://github.com/orgs/Homebrew/discussions/4311)

### Bash Scripting Best Practices
- [How to write idempotent Bash scripts](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/)
- [The Truth About Curl and Installing Software Securely](https://medium.com/@esotericmeans/the-truth-about-curl-and-installing-software-securely-on-linux-63cd12e7befd)
- [Best practices when using Curl in shell scripts](https://www.joyfulbikeshedding.com/blog/2020-05-11-best-practices-when-using-curl-in-shell-scripts.html)
- [Rustup Security Documentation](https://rust-lang.github.io/rustup/security.html)

---

**Status**: ✅ All research complete. Ready for Phase 1 (Design & Contracts).
