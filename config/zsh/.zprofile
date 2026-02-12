# ~/.zprofile - Login shell configuration for zsh

# Add ~/bin to PATH if it exists
if [ -d "$HOME/bin" ]; then
    export PATH="$HOME/bin:$PATH"
fi

# User-specific environment and startup programs below
