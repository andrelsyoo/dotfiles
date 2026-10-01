# Dotfiles

Shell config and bootstrap scripts for my machines — macOS (primary) and Ubuntu (any box — bare metal, cloud instance, or VM, arm64 or amd64).

Shared dotfiles live at the repo root and are symlinked into `~` with [GNU Stow](https://www.gnu.org/software/stow/). Per-OS setup scripts live in `macos/` and `linux/` and are run directly, never symlinked.

## Layout

```
dotfiles/
├── .zshrc                            # stowed into ~
├── .gitconfig                        # stowed into ~
├── .stow-local-ignore                # keeps scripts/docs out of ~
├── macos/
│   ├── install_oh_my_zsh_and_brew.sh
│   ├── brew.sh
│   └── install-commitizen.sh
└── linux/
    └── bootstrap-ubuntu.sh
```

| File / Script | Purpose |
|---|---|
| `.zshrc` | Zsh config — Oh My Zsh, theme, plugins, aliases |
| `.gitconfig` | Git user config and defaults |
| `macos/install_oh_my_zsh_and_brew.sh` | Bootstrap: installs Homebrew, Zsh, Oh My Zsh, and plugins |
| `macos/brew.sh` | Installs all Homebrew formulae and casks |
| `macos/install-commitizen.sh` | Installs Commitizen globally for conventional commits |
| `linux/bootstrap-ubuntu.sh` | One-shot Ubuntu dev setup — see [Ubuntu](#bootstrap--ubuntu) below |

---

## Bootstrap — new Mac setup

Run these steps in order.

### 1. Clone the repo

```sh
git clone https://github.com/andrelsyoo/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. Install Homebrew + Oh My Zsh

```sh
./macos/install_oh_my_zsh_and_brew.sh
```

Pass `yes` to also set Zsh as the default shell:

```sh
./macos/install_oh_my_zsh_and_brew.sh yes
```

This installs:
- [Homebrew](https://brew.sh/)
- Zsh
- [Oh My Zsh](https://ohmyzsh.sh/) with plugins: `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`

### 3. Install Homebrew packages

```sh
./macos/brew.sh
```

Installs all CLI tools, languages, and Mac apps. See [what's installed](#homebrew-packages) below. This also installs `stow`, which is needed for the next step.

### 4. Symlink dotfiles

```sh
stow .
```

Creates symlinks from `~/dotfiles/` into `~`. Only the root-level dotfiles are linked — `macos/`, `linux/` and `README.md` are excluded by `.stow-local-ignore`.

If Oh My Zsh already created a `~/.zshrc`, remove it first to avoid conflicts:

```sh
rm ~/.zshrc
stow .
```

### 5. Set up Commitizen

```sh
./macos/install-commitizen.sh
```

Installs [Commitizen](https://commitizen-tools.github.io/commitizen/) and the conventional changelog adapter globally. After this, use `git cz` instead of `git commit` in any repository.

---

## Bootstrap — Ubuntu

`linux/bootstrap-ubuntu.sh` sets up a fresh Ubuntu box (bare metal, cloud instance, or VM — arm64 or amd64) for dev work. It is self-contained — it does **not** depend on this repo being cloned, and it does not use stow.

If you're already logged in as your own user, it's a **single run** that installs everything. If the box instead ships with a separate default admin user (e.g. Parallels' `parallels` user), run it in **two phases**:

| Phase | Run as | What it does |
|---|---|---|
| 1 | the default admin user | System packages, hostname, Chrome, VS Code, Slacky, Parallels Tools check (skipped outside Parallels), then creates your own admin user and stops |
| 2 | your new user | Removes the old default user (optional), Git + SSH key, zsh/Oh My Zsh/agnoster, Nerd Font, Homebrew, toolbox, tflint, gcloud, Commitizen |

### Usage

```sh
bash bootstrap-ubuntu.sh
```

Log out after phase 1, log back in as the new user, then run it again — the script copies itself to the new user's home, so phase 2 is:

```sh
bash ~/bootstrap-ubuntu.sh
```

Every step is idempotent: re-running skips whatever is already done. A failed step warns and continues, and all failures are listed again at the end.

> If you launch it from a shared/network folder (e.g. a Parallels shared folder under `/media/psf/...`), it copies itself to `$HOME` and re-execs from there — the apt upgrade can drop that mount mid-run.

### Overrides

Defaults are set at the top of the script and can be overridden by env var or answered at the interactive prompts:

```sh
NEW_USER=you GIT_NAME="Your Name" GIT_EMAIL=me@example.com bash bootstrap-ubuntu.sh
```

| Variable | Default | Purpose |
|---|---|---|
| `NEW_HOSTNAME` | `ubuntu-dev` | VM hostname |
| `NEW_USER` | `dev` | Admin user created in phase 1 |
| `GIT_NAME` | *(empty)* | `git config --global user.name` |
| `GIT_EMAIL` | *(empty)* | `git config --global user.email` |
| `TOOLBOX_REPO` | *(empty)* | SSH URL of the devops toolbox repo; blank skips the step |
| `TOOLBOX_DIR` | `~/toolbox` | Where the toolbox is cloned |
| `DELETE_PARALLELS` | `n` | Remove the old default admin user (e.g. Parallels' `parallels` user) and its home |

All of these are also asked interactively on first run (Enter keeps the default/env value above), so leaving them unset just means you'll be prompted.

### Manual steps it can't do for you

- **Parallels Tools** (Parallels VMs only) — install from the Mac menu bar (Actions → Install Parallels Tools), then run the installer inside Ubuntu and reboot. The script only detects (and skips entirely on non-Parallels boxes) and warns.
- **GitHub SSH key** — the script generates the key and prints it; you paste it into GitHub → Settings → SSH and GPG keys, and it retries the connection check up to 3 times.
- **Slack on amd64** — Slacky is ARM64-only; grab the official `.deb` from slack.com instead.

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
