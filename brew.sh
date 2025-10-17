#!/usr/bin/env bash

# Install command-line tools using Homebrew.

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
ln -s "${BREW_PREFIX}/bin/gsha256sum" "${BREW_PREFIX}/bin/sha256sum"

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed
# Install a modern version of Bash.
brew install bash
brew install bash-completion2
brew install --cask iterm2

# Switch to using brew-installed bash as default shell
if ! fgrep -q "${BREW_PREFIX}/bin/bash" /etc/shells; then
  echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
  chsh -s "${BREW_PREFIX}/bin/bash";
fi;

# Install `wget` 
brew install wget

# Install GnuPG to enable PGP-signing commits.
brew install gnupg

# Install more recent versions of some macOS tools.
brew install vim
brew install grep
brew install openssh
brew install screen
brew install gmp

# Install password manager.
brew install --cask 1password

# Install tools.
brew install ansible
brew install autoconf
brew install awscli
brew install argocd
brew install azure-cli
brew install docker-credential-helper
brew install flux
brew install warrensbox/tap/tfswitch
brew install grep
brew install --cask intellij-idea-ce
brew install k9s
brew install kubernetes-cli
brew install pyenv
brew install python-packaging
brew install python@3.12
brew install python@3.13
brew install node
brew install kustomize
brew install redis
brew install rsync
brew install stow
brew install --cask sublime-text
brew install --cask slack
brew install telnet
brew install tfenv
brew install tfswitch
brew install helm
brew install yq
brew install --cask windows-app

# Install other useful binaries.
brew install git
brew install git-lfs

# Remove outdated versions from the cellar.
brew cleanup
