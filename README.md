# Dotfiles

Automated dotfiles setup for macOS using Homebrew and GNU Stow.

## Quick Installation

Run this one command to set up your entire development environment:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/timgentry/dotfiles/main/install.sh)
```

This will:
- Install Homebrew (if not already installed)
- Install packages from Brewfile
- Symlink configuration files to your home directory
- Add utility scripts to your PATH
- Apply global configurations

### First Run

On first run, you'll be asked to confirm before making system-wide changes.

### Subsequent Runs

Updates are applied automatically without confirmation. Safe to run multiple times.

## What Gets Installed

### Homebrew Packages

See [`Brewfile`](Brewfile) for the complete list of packages.

Essential packages:
- `git` - Version control
- `stow` - Symlink manager
- `bash` - Bash 5.x

### Configuration Files

Your dotfiles are symlinked from this repository to your home directory:

- **Zsh**: `~/.zshrc`, `~/.zprofile` (default shell on modern macOS)
- **Git**: `~/.gitconfig`
- **Gem**: `~/.gemrc`

### Utility Scripts

Scripts in `bin/` are added to your PATH:

- **gh-open**: Open current git branch in browser on GitHub

## Verification

After installation, verify everything works:

```bash
# Check Homebrew
brew --version

# Check PATH includes ~/bin
echo $PATH | grep "$HOME/bin"

# Test utility script (in a git repository)
gh-open
```

Or run the validation script:

```bash
~/.dotfiles/.dotfiles/validate-quickstart.sh
```

## Updating Your Dotfiles

### Pull latest changes:

```bash
cd ~/.dotfiles
git pull origin main
```

### Re-run setup:

```bash
~/.dotfiles/.dotfiles/setup.sh
```

Or use the remote installer again (safe to run multiple times):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/timgentry/dotfiles/main/install.sh)
```

## Customization

### Adding Packages

Edit [`Brewfile`](Brewfile):

```ruby
brew "fzf"
brew "ripgrep"
cask "visual-studio-code"
```

Then run:

```bash
brew bundle install
```

### Adding Configuration Files

1. Create a package directory:
   ```bash
   mkdir -p ~/.dotfiles/config/myapp
   ```

2. Add your config file:
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

3. Test it:
   ```bash
   my-script
   ```

## Project Structure

```
dotfiles/
├── install.sh           # Remote bootstrap script (curl | bash entry point)
├── Brewfile             # Homebrew package definitions
├── .dotfiles/
│   ├── setup.sh         # Main setup orchestrator
│   ├── lib/             # Library functions
│   │   ├── utils.sh     # Logging, platform detection, confirmations
│   │   ├── state.sh     # First-run detection, state persistence
│   │   ├── homebrew.sh  # Homebrew installation and management
│   │   ├── stow.sh      # GNU Stow operations
│   │   └── config.sh    # Configuration verification
│   └── validate-quickstart.sh  # Validation script
├── config/              # Configuration files (stowed to ~)
│   ├── zsh/             # Zsh shell configuration
│   ├── git/
│   └── gem/
└── bin/                 # Utility scripts (stowed to ~/bin)
    └── gh-open
```

## Troubleshooting

### Homebrew Not Found After Installation

Restart your shell:

```bash
exec $SHELL
```

Or manually source the configuration:

```bash
source ~/.zshrc  # or ~/.bash_profile
```

### Stow Conflicts

If Stow reports conflicts with existing files:

**Option 1**: Backup and stow
```bash
mv ~/.bashrc ~/.bashrc.backup
cd ~/.dotfiles && stow config/bash
```

**Option 2**: Adopt existing file
```bash
cd ~/.dotfiles && stow --adopt config/bash
```

### Utility Scripts Not in PATH

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

### Check Logs

View the setup log for errors:

```bash
cat ~/.dotfiles/setup.log
```

Or view recent entries:

```bash
tail -20 ~/.dotfiles/setup.log
```

## Advanced Usage

### Non-Interactive Mode

For automation or CI/CD:

```bash
NONINTERACTIVE=1 bash <(curl -fsSL https://raw.githubusercontent.com/timgentry/dotfiles/main/install.sh)
```

### Skip Homebrew Installation

```bash
SKIP_HOMEBREW=1 ~/.dotfiles/.dotfiles/setup.sh
```

### Skip Stow Operations

```bash
SKIP_STOW=1 ~/.dotfiles/.dotfiles/setup.sh
```

## File Locations

- **Dotfiles repository**: `~/.dotfiles`
- **Setup script**: `~/.dotfiles/.dotfiles/setup.sh`
- **State file**: `~/.dotfiles_state`
- **Setup log**: `~/.dotfiles/setup.log`

## License

This is personal dotfiles configuration. Feel free to fork and customize for your own use.

## Credits

Built using:
- [Homebrew](https://brew.sh/) - Package manager for macOS
- [GNU Stow](https://www.gnu.org/software/stow/) - Symlink farm manager
