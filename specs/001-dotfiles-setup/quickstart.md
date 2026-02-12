# Quickstart Guide: Dotfiles Setup

**Feature**: Dotfiles Setup Command
**Date**: 2026-02-12

This guide provides quick instructions for users to install and use the dotfiles setup system.

---

## Installation

### One-Command Setup

Run this command in your terminal to set up everything:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/install.sh)
```

**What this does**:
1. Downloads the dotfiles repository to `~/.dotfiles`
2. Installs Homebrew (if not present)
3. Installs packages from Brewfile
4. Symlinks configuration files to your home directory
5. Adds utility scripts to your PATH

**First run**: You'll be asked to confirm before making system-wide changes.

**Subsequent runs**: Updates are applied automatically without confirmation.

---

## What Gets Installed

### Homebrew Packages

The setup installs packages defined in the Brewfile, such as:
- Development tools (git, stow, etc.)
- Command-line utilities
- GUI applications (optional)

View the full list: `~/.dotfiles/Brewfile`

### Configuration Files

Your dotfiles are symlinked to the appropriate locations:

- **Bash**: `~/.bashrc`, `~/.bash_profile`
- **Zsh**: `~/.zshrc`
- **Git**: `~/.gitconfig`
- **Gem**: `~/.gemrc`

### Utility Scripts

Useful scripts are added to your PATH (`~/bin`):

- **gh-open**: Open current git branch in browser on GitHub

---

## Verifying Installation

### Check Installed Packages

```bash
# List installed Homebrew packages
brew list

# Check if Brewfile packages are installed
cd ~/.dotfiles && brew bundle check
```

### Check Symlinks

```bash
# Verify config files are symlinked
ls -la ~/ | grep '\->'

# Example output:
# .bashrc -> .dotfiles/config/bash/.bashrc
# .gitconfig -> .dotfiles/config/git/.gitconfig
```

### Test Utility Scripts

```bash
# Verify bin directory is in PATH
echo $PATH | grep "$HOME/bin"

# Test gh-open script (in a git repository)
cd /path/to/git/repo
gh-open  # Opens current branch in browser
```

---

## Updating Your Dotfiles

### Pulling Latest Changes

```bash
cd ~/.dotfiles
git pull origin main
```

### Re-running Setup

After pulling changes, re-run the setup to apply updates:

```bash
~/.dotfiles/.dotfiles/setup.sh
```

Or use the remote installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/install.sh)
```

**Note**: Updates run automatically without confirmation.

---

## Customization

### Adding New Packages

Edit the Brewfile:

```bash
vim ~/.dotfiles/Brewfile
```

Add packages:

```ruby
# CLI tools
brew "fzf"
brew "ripgrep"

# GUI applications
cask "visual-studio-code"
```

Then run:

```bash
cd ~/.dotfiles && brew bundle install
```

### Adding New Configuration Files

1. Create a package directory:

```bash
mkdir -p ~/.dotfiles/config/myapp
```

2. Add configuration files:

```bash
cp ~/.myapprc ~/.dotfiles/config/myapp/
```

3. Stow the package:

```bash
cd ~/.dotfiles && stow config/myapp
```

4. Commit to git:

```bash
git add config/myapp
git commit -m "Add myapp configuration"
```

### Adding Utility Scripts

1. Create script in `bin/`:

```bash
vim ~/.dotfiles/bin/my-script
```

2. Make executable:

```bash
chmod +x ~/.dotfiles/bin/my-script
```

3. Stow bin directory (if not already):

```bash
cd ~/.dotfiles && stow bin
```

4. Test script:

```bash
my-script
```

---

## Troubleshooting

### Homebrew Not Found After Installation

If `brew` command is not found, restart your shell:

```bash
exec $SHELL
```

Or manually source the configuration:

```bash
# For Zsh
source ~/.zshrc

# For Bash
source ~/.bash_profile
```

### Stow Conflicts

If Stow reports conflicts (existing files), you have options:

**Option 1: Backup and stow**

```bash
mv ~/.bashrc ~/.bashrc.backup
cd ~/.dotfiles && stow config/bash
```

**Option 2: Adopt existing file**

```bash
cd ~/.dotfiles && stow --adopt config/bash
```

This moves your existing file into the dotfiles repository.

**Option 3: Review differences**

```bash
diff ~/.bashrc ~/.dotfiles/config/bash/.bashrc
```

Decide whether to keep existing or use dotfiles version.

### Utility Scripts Not in PATH

If scripts don't work after installation:

1. Check if `~/bin` is in PATH:

```bash
echo $PATH
```

2. If missing, add to shell config:

```bash
# Add to ~/.zshrc or ~/.bash_profile
export PATH="$HOME/bin:$PATH"
```

3. Restart shell:

```bash
exec $SHELL
```

### Brewfile Installation Failed

If some packages fail to install:

1. Check which packages failed:

```bash
cd ~/.dotfiles && brew bundle check --verbose
```

2. Try installing individual packages:

```bash
brew install <package-name>
```

3. Check for incompatibility:

```bash
brew info <package-name>
```

---

## Advanced Usage

### Non-Interactive Mode

For automation or CI/CD:

```bash
NONINTERACTIVE=1 bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/install.sh)
```

### Custom Installation Directory

```bash
DOTFILES_DIR=~/my-dotfiles bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/install.sh)
```

### Skip Homebrew Installation

```bash
SKIP_HOMEBREW=1 ~/.dotfiles/.dotfiles/setup.sh
```

### Skip Stow Operations

```bash
SKIP_STOW=1 ~/.dotfiles/.dotfiles/setup.sh
```

### Custom Brewfile

```bash
BREWFILE=~/custom-Brewfile ~/.dotfiles/.dotfiles/setup.sh
```

---

## Uninstalling

### Unstow Configuration Files

Remove symlinks:

```bash
cd ~/.dotfiles
stow -D config/*
```

### Remove Dotfiles Repository

```bash
rm -rf ~/.dotfiles
```

### Remove State File

```bash
rm ~/.dotfiles_state
```

**Note**: This doesn't uninstall Homebrew or packages. To remove Homebrew:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
```

---

## File Locations

### Important Paths

- **Dotfiles repository**: `~/.dotfiles`
- **Setup script**: `~/.dotfiles/.dotfiles/setup.sh`
- **Brewfile**: `~/.dotfiles/Brewfile`
- **Config packages**: `~/.dotfiles/config/`
- **Utility scripts**: `~/.dotfiles/bin/`
- **State file**: `~/.dotfiles_state`
- **Setup log**: `~/.dotfiles/setup.log`

### Shell Configuration

The setup modifies these files:

- **Zsh users**: `~/.zshrc`
- **Bash users**: `~/.bash_profile`

Changes include:
- Homebrew shell environment (`brew shellenv`)
- Adding `~/bin` to PATH

---

## Getting Help

### View Setup Log

```bash
cat ~/.dotfiles/setup.log
```

Or view recent entries:

```bash
tail -20 ~/.dotfiles/setup.log
```

### Check Installation State

```bash
cat ~/.dotfiles_state
```

Example output:

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

### Report Issues

If you encounter problems:

1. Check the setup log for errors
2. Verify dependencies are installed (git, curl)
3. Try re-running setup with verbose output
4. Open an issue on GitHub with log contents

---

## Best Practices

### Keep Dotfiles Updated

Regularly pull and apply updates:

```bash
cd ~/.dotfiles && git pull && ~/.dotfiles/.dotfiles/setup.sh
```

### Commit Your Changes

After customizing:

```bash
cd ~/.dotfiles
git add .
git commit -m "Update configuration"
git push origin main
```

### Test Before Committing

Test changes on a new machine or VM before committing to ensure portability.

### Document Custom Settings

Add comments to configuration files explaining non-obvious settings.

### Version Lock Critical Packages

In Brewfile, pin versions for stability:

```ruby
brew "node", version: "18.0.0"
```

---

**Need more help?** Check the [full documentation](../plan.md) or [implementation details](../research.md).
