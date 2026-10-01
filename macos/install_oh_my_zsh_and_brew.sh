#!/bin/bash
# Exit on error
set -e

# Function to print messages
log() {
    echo -e "\e[32m$1\e[0m"
}

# Check for argument and set default if none provided
MAKE_DEFAULT_SHELL="${1:-no}"

# Display the selected option
log "Make Zsh default shell: $MAKE_DEFAULT_SHELL"

# Install Homebrew if not installed
if ! command -v brew &>/dev/null; then
    log "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for the current session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon Mac
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        # Intel Mac
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    log "Homebrew installed successfully."
else
    log "Homebrew is already installed."
fi

# Install Zsh (if not installed)
if ! command -v zsh &>/dev/null; then
    log "Installing Zsh..."
    brew install zsh
else
    log "Zsh is already installed."
fi

# Install git and curl if missing
for cmd in git curl; do
    if ! command -v $cmd &>/dev/null; then
        log "Installing $cmd..."
        brew install $cmd
    else
        log "$cmd is already installed."
    fi
done

# Install Oh My Zsh if not already installed
if [ -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh is already installed at $HOME/.oh-my-zsh. Skipping."
else
    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Set Zsh as the default shell if requested
if [[ "$MAKE_DEFAULT_SHELL" == "yes" ]]; then
    log "Setting Zsh as the default shell..."
    chsh -s "$(which zsh)"
else
    log "Zsh installation complete. Skipping setting it as default shell."
fi

# Install Zsh autosuggestions
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    log "Installing Zsh autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
else
    log "Zsh autosuggestions already installed. Skipping."
fi

# Install Zsh syntax highlighting
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    log "Installing Zsh syntax highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
else
    log "Zsh syntax highlighting already installed. Skipping."
fi

# Install Zsh completions
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" ]; then
    log "Installing Zsh completions..."
    git clone https://github.com/zsh-users/zsh-completions "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"
else
    log "Zsh completions already installed. Skipping."
fi

# Get the real path of .zshrc (follows symlinks)
ZSHRC_PATH="$HOME/.zshrc"
if [ -L "$ZSHRC_PATH" ]; then
    ZSHRC_REAL_PATH=$(readlink "$ZSHRC_PATH")
    # Handle relative symlinks
    if [[ "$ZSHRC_REAL_PATH" != /* ]]; then
        ZSHRC_REAL_PATH="$HOME/$ZSHRC_REAL_PATH"
    fi
    log "Detected .zshrc is a symlink pointing to: $ZSHRC_REAL_PATH"
else
    ZSHRC_REAL_PATH="$ZSHRC_PATH"
fi

# Configure plugins in .zshrc
log "Configuring Zsh plugins in .zshrc..."
if ! grep -q "zsh-autosuggestions" "$ZSHRC_REAL_PATH"; then
    sed -i.bak 's/plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)/' "$ZSHRC_REAL_PATH"
    rm "${ZSHRC_REAL_PATH}.bak"
    log "Updated plugins in .zshrc."
else
    log "Plugins already configured in .zshrc."
fi

# Add fpath for zsh-completions (required for it to work properly)
if ! grep -q "fpath+=\${ZSH_CUSTOM:-\${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src" "$ZSHRC_REAL_PATH"; then
    log "Adding fpath configuration for zsh-completions..."
    # Insert before Oh My Zsh is sourced
    sed -i.bak '/^source \$ZSH\/oh-my-zsh.sh/i\
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
' "$ZSHRC_REAL_PATH"
    rm "${ZSHRC_REAL_PATH}.bak"
    log "Added fpath configuration."
else
    log "fpath already configured for zsh-completions."
fi

# Apply the changes (reload .zshrc)
log "Applying changes..."
zsh -c "source ~/.zshrc"

log "Oh My Zsh installation completed with autosuggestions, syntax highlighting, and completions enabled!"