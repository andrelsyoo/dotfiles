# Dotfiles for my Mac setup

macOS configuration and bootstrap scripts. Managed with [GNU Stow](https://www.gnu.org/software/stow/) — dotfiles live in `~/dotfiles` and are symlinked into `~`.

## What's included

| File / Script | Purpose |
|---|---|
| `.zshrc` | Zsh config — Oh My Zsh, theme, plugins, aliases |
| `.gitconfig` | Git user config and defaults |
| `install_oh_my_zsh_and_brew.sh` | Bootstrap: installs Homebrew, Zsh, Oh My Zsh, and plugins |
| `brew.sh` | Installs all Homebrew formulae and casks |
| `install-commitizen.sh` | Installs Commitizen globally for conventional commits |

## Bootstrap — new Mac setup

Run these steps in order.

### 1. Clone the repo

```sh
git clone https://github.com/andrelsyoo/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. Install Homebrew + Oh My Zsh

```sh
./install_oh_my_zsh_and_brew.sh
```

Pass `yes` to also set Zsh as the default shell:

```sh
./install_oh_my_zsh_and_brew.sh yes
```

This installs:
- [Homebrew](https://brew.sh/)
- Zsh
- [Oh My Zsh](https://ohmyzsh.sh/) with plugins: `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`

### 3. Install Homebrew packages

```sh
./brew.sh
```

Installs all CLI tools, languages, and Mac apps. See [what's installed](#homebrew-packages) below. This also installs `stow`, which is needed for the next step.

### 4. Symlink dotfiles

```sh
stow .
```

Creates symlinks from `~/dotfiles/` into `~`. If Oh My Zsh already created a `~/.zshrc`, remove it first to avoid conflicts:

```sh
rm ~/.zshrc
stow .
```

### 5. Set up Commitizen

```sh
./install-commitizen.sh
```

Installs [Commitizen](https://commitizen-tools.github.io/commitizen/) and the conventional changelog adapter globally. After this, use `git cz` instead of `git commit` in any repository.

---

## Shell setup

**Theme:** [agnoster](https://github.com/agnoster/agnoster-zsh-theme)

**Plugins:**

| Plugin | What it does |
|---|---|
| `zsh-autosuggestions` | Fish-like inline command suggestions based on history |
| `zsh-syntax-highlighting` | Highlights valid commands in green, errors in red |
| `zsh-completions` | Additional tab completions for many CLI tools |
| `git` | Git aliases (`gst`, `gco`, `gp`, etc.) and completions |
| `kubectl` | `kubectl` completions and the `k` alias |
| `helm` | Helm completions |
| `aws` | AWS CLI completions |
| `macos` | macOS-specific utilities (`ofd`, `cdf`, etc.) |
| `sudo` | Press `Esc Esc` to prefix the last command with `sudo` |

**Aliases:**

```sh
k   → kubectl
g   → git
tf  → terraform
tg  → terragrunt
```

---

## Homebrew packages

### CLI tools

| Tool | Description |
|---|---|
| `git`, `git-lfs` | Version control |
| `awscli`, `azure-cli` | Cloud CLIs |
| `ansible` | Configuration management |
| `wget`, `curl` | HTTP |
| `yq` | YAML processor |
| `stow` | Dotfile symlink manager |
| `rsync` | File sync |
| `gnupg` | GPG encryption |
| `opentofu` | Infrastructure as code (open-source Terraform) |
| `tfswitch`, `tfenv` | Terraform version managers |

### Kubernetes

| Tool | Description |
|---|---|
| `kubectl` | Kubernetes CLI |
| `helm` | Kubernetes package manager |
| `k9s` | Terminal UI for Kubernetes |
| `argocd` | ArgoCD CLI |
| `talosctl` | Talos Linux CLI |
| `kustomize` | Kubernetes config management |
| `flux` | Flux GitOps CLI |

### Languages & runtimes

| Tool | Description |
|---|---|
| `python@3.12`, `python@3.13` | Python |
| `pyenv` | Python version manager |
| `node` | Node.js (required for Commitizen) |

### Apps (casks)

| App | Description |
|---|---|
| iTerm2 | Terminal emulator |
| Visual Studio Code | Code editor |
| Sublime Text | Text editor |
| Claude | Anthropic desktop app |
| Slack | Messaging |
| 1Password | Password manager |
| Windows App | Remote desktop (RDP) |
| Remote Desktop Manager | Multi-protocol remote access |
