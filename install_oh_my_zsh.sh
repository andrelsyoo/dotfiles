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
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
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

# Configure plugins in .zshrc
log "Configuring Zsh plugins in .zshrc..."
if ! grep -q "zsh-autosuggestions" ~/.zshrc; then
    sed -i '' 's/plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
    log "Updated plugins in .zshrc."
else
    log "Plugins already configured in .zshrc."
fi

# Apply the changes (reload .zshrc)
log "Applying changes..."
zsh -c "source ~/.zshrc"

log "Oh My Zsh installation completed with autosuggestions and syntax highlighting enabled!"
