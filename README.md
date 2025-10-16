# Dotfiles symlinked on my machine

### Install with stow:
```bash
stow .
```

### Install Homebrew formulae

When setting up a new Mac, you may want to install some common [Homebrew](https://brew.sh/) formulae (after installing Homebrew, of course):

```bash
./brew.sh
```

### Setting Oh My Zsh Installer with Plugins

```bash
./install_oh_my_zsh.sh [yes|no]
```

yes: Install Zsh and set it as the default shell.

no (default): Install Zsh without changing the default shell.

### Install Commitizen globally so it works in any repository without per-project setup

```bash
./install-commitizen.sh
```