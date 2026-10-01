#!/usr/bin/env bash
# =============================================================================
# bootstrap-ubuntu.sh — rebuild Andre's Ubuntu dev setup
#
# Works on any fresh Ubuntu box (bare metal, cloud instance, or VM — arm64 or
# amd64). If the box ships with a separate default admin user (e.g. Parallels'
# "parallels"), run it twice:
#   1) As that default user  -> installs system apps, sets hostname,
#      creates your new user, then tells you to log out.
#   2) As your new user (e.g. "andre")   -> removes the old default user
#      (optional), git + SSH key, zsh/Oh My Zsh/agnoster, Nerd Font, Homebrew,
#      toolbox, tflint, gcloud PATH, npm Commitizen (with "chore").
# Otherwise (already logged in as your own user) one run does everything.
#
# Usage:   bash bootstrap-ubuntu.sh
# Safe to re-run: every step skips what's already done.
# Defaults can be overridden with env vars, e.g.:
#   NEW_USER=andre GIT_EMAIL=me@example.com bash bootstrap-ubuntu.sh
# =============================================================================
set -uo pipefail

# If started from a shared/network folder (e.g. a Parallels shared folder under
# /media/psf), copy to $HOME and re-run from there: bash reads scripts as it
# goes, and the apt upgrade can briefly disconnect a network/shared mount mid-run.
if [[ "$(readlink -f "$0")" != "$HOME/bootstrap-ubuntu.sh" ]]; then
  cp "$0" "$HOME/bootstrap-ubuntu.sh" && chmod +x "$HOME/bootstrap-ubuntu.sh" &&
  exec bash "$HOME/bootstrap-ubuntu.sh" "$@"
fi

# ---------- settings (edit here or override via env) ----------
NEW_HOSTNAME="${NEW_HOSTNAME:-ubuntu-dev}"
NEW_USER="${NEW_USER:-dev}"
GIT_NAME="${GIT_NAME:-}"
GIT_EMAIL="${GIT_EMAIL:-}"
TOOLBOX_REPO="${TOOLBOX_REPO:-}"                 # e.g. git@github.com:ORG/devops.git (blank = skip)
TOOLBOX_DIR="${TOOLBOX_DIR:-$HOME/toolbox}"
DELETE_PARALLELS="${DELETE_PARALLELS:-n}"
NERD_FONT="JetBrainsMono"
TERMINAL_FONT="JetBrainsMono Nerd Font Mono 12"
BREW="/home/linuxbrew/.linuxbrew/bin/brew"

# ---------- helpers ----------
c_b=$'\e[1;34m'; c_g=$'\e[1;32m'; c_y=$'\e[1;33m'; c_r=$'\e[1;31m'; c_0=$'\e[0m'
say()  { printf '\n%s==>%s %s\n' "$c_b" "$c_0" "$*"; }
ok()   { printf '%s  ✓%s %s\n' "$c_g" "$c_0" "$*"; }
warn() { printf '%s  !%s %s\n' "$c_y" "$c_0" "$*"; }
FAILED=()
step() {  # step "Name" command args...
  local name="$1"; shift
  say "$name"
  if "$@"; then ok "$name"; else warn "$name failed — continuing"; FAILED+=("$name"); fi
}
have()     { command -v "$1" >/dev/null 2>&1; }
add_line() { touch "$2"; grep -qxF "$1" "$2" || printf '%s\n' "$1" >> "$2"; }
ask() {    # ask VAR "Prompt"   (keeps default on Enter)
  local var="$1" prompt="$2" reply
  read -r -p "$prompt [${!var}]: " reply </dev/tty
  printf -v "$var" '%s' "${reply:-${!var}}"
}
install_deb_url() {  # install_deb_url URL name
  local dir; dir="$(mktemp -d)"; chmod 755 "$dir"
  curl -fL --retry 3 -o "$dir/$2.deb" "$1" && sudo apt-get install -y "$dir/$2.deb"
  local rc=$?; rm -rf "$dir"; return $rc
}

# ---------- pre-flight ----------
if [[ $EUID -eq 0 ]]; then echo "Run as your normal user, not with sudo."; exit 1; fi
ARCH="$(dpkg --print-architecture)"   # arm64 on Apple-chip Macs, amd64 on Intel
SCRIPT_PATH="$(readlink -f "$0")"
say "Ubuntu bootstrap — user: $USER, arch: $ARCH"
sudo -v || exit 1
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
SUDO_KEEPALIVE=$!
trap 'kill $SUDO_KEEPALIVE 2>/dev/null' EXIT

PHASE="user"
[[ "$USER" == "parallels" ]] && PHASE="parallels"

say "A few questions first (press Enter to keep the default)"
ask NEW_HOSTNAME "Hostname"
if [[ "$PHASE" == "parallels" ]]; then
  ask NEW_USER "New username to create (lowercase, no dots)"
  [[ "$NEW_USER" == "parallels" ]] && PHASE="user"
fi
if [[ "$PHASE" == "user" ]]; then
  ask GIT_NAME  "Git name"
  ask GIT_EMAIL "Git email (the one on your GitHub account)"
  ask TOOLBOX_REPO "Toolbox repo SSH URL (blank to skip)"
  if [[ "$USER" != "parallels" ]] && id parallels >/dev/null 2>&1; then
    ask DELETE_PARALLELS "Delete the old 'parallels' user and its home folder? (y/n)"
  fi
fi

# =============================================================================
# System-wide steps (run in both phases; skip if already done)
# =============================================================================
sys_base() {
  sudo apt-get update &&
  sudo apt-get -y upgrade &&
  sudo apt-get install -y curl wget git unzip zsh build-essential procps file \
       ca-certificates gnupg openssh-client fonts-powerline fontconfig
}

sys_hostname() {
  local old; old="$(hostname)"
  [[ "$old" == "$NEW_HOSTNAME" ]] && return 0
  sudo hostnamectl set-hostname "$NEW_HOSTNAME" &&
  sudo sed -i "s/\b${old}\b/${NEW_HOSTNAME}/g" /etc/hosts
}

sys_chrome() {
  have google-chrome-stable && return 0
  install_deb_url "https://dl.google.com/linux/direct/google-chrome-stable_current_${ARCH}.deb" chrome
}

sys_vscode() {
  have code && return 0
  local os="linux-deb-${ARCH}"; [[ "$ARCH" == "amd64" ]] && os="linux-deb-x64"
  echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
  install_deb_url "https://code.visualstudio.com/sha/download?build=stable&os=${os}" code
}

sys_slacky() {
  if [[ "$ARCH" != "arm64" ]]; then
    warn "Not arm64 — install the official Slack .deb from slack.com instead"; return 0
  fi
  dpkg -l | grep -qi slacky && return 0
  local url
  url="$(curl -fsSL https://api.github.com/repos/andirsun/Slacky/releases/latest \
        | grep -o '"browser_download_url": *"[^"]*arm64\.deb"' | head -1 | cut -d'"' -f4)"
  [[ -n "$url" ]] || { warn "Couldn't find a Slacky arm64 .deb in the latest release"; return 1; }
  install_deb_url "$url" slacky
}

sys_parallels_tools() {
  # No-op unless this is actually a Parallels VM.
  [[ "$(systemd-detect-virt 2>/dev/null)" == "parallels" ]] || return 0
  if systemctl list-unit-files 2>/dev/null | grep -q '^prltoolsd'; then return 0; fi
  warn "Parallels Tools not detected. On the Mac menu bar: Actions → Install Parallels Tools,"
  warn "then in Ubuntu: cd \"/media/\$USER/Parallels Tools\" && sudo ./install  (and reboot)"
  return 0
}

step "System packages (apt update/upgrade + basics)" sys_base
step "Hostname → $NEW_HOSTNAME"                      sys_hostname
step "Google Chrome ($ARCH)"                          sys_chrome
step "VS Code ($ARCH)"                                sys_vscode
step "Slacky (Slack app for arm64)"                   sys_slacky
step "1Password CLI group"                            sudo groupadd -f onepassword-cli
step "Parallels Tools check"                          sys_parallels_tools

# =============================================================================
# Phase 1 end: create the new user, then stop
# =============================================================================
create_user() {
  if ! id "$NEW_USER" >/dev/null 2>&1; then
    [[ "$NEW_USER" =~ ^[a-z][-a-z0-9_]*$ ]] || {
      warn "Invalid username '$NEW_USER' (lowercase letters, digits, - and _ only; no dots)"; return 1; }
    echo "Set a password for $NEW_USER (other questions: just press Enter):"
    sudo adduser "$NEW_USER" </dev/tty || return 1
  fi
  sudo usermod -aG sudo "$NEW_USER" || return 1
  if [[ -f /etc/gdm3/custom.conf ]] && grep -q '^AutomaticLogin=' /etc/gdm3/custom.conf; then
    sudo sed -i "s/^AutomaticLogin=.*/AutomaticLogin=$NEW_USER/" /etc/gdm3/custom.conf
  fi
  sudo install -o "$NEW_USER" -g "$NEW_USER" -m 755 "$SCRIPT_PATH" "/home/$NEW_USER/bootstrap-ubuntu.sh"
}

if [[ "$PHASE" == "parallels" ]]; then
  step "Create user $NEW_USER (admin)" create_user
  echo
  say "Phase 1 done."
  echo "  1. Log out (top-right → Power → Log Out) and log in as '$NEW_USER'."
  echo "  2. Open a Terminal and run:   bash ~/bootstrap-ubuntu.sh"
  [[ ${#FAILED[@]} -gt 0 ]] && warn "Steps that failed: ${FAILED[*]}"
  exit 0
fi

# =============================================================================
# Phase 2: everything for your own user
# =============================================================================
remove_parallels_user() {
  [[ "$DELETE_PARALLELS" =~ ^[Yy] ]] || return 0
  id parallels >/dev/null 2>&1 || return 0
  sudo pkill -KILL -u parallels 2>/dev/null; sleep 1
  sudo deluser --remove-home parallels
}

user_git() {
  { [[ -z "$GIT_NAME" ]]  || git config --global user.name "$GIT_NAME"; } &&
  { [[ -z "$GIT_EMAIL" ]] || git config --global user.email "$GIT_EMAIL"; }
}

user_ssh_key() {
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  if [[ ! -f ~/.ssh/id_ed25519 ]]; then
    echo "Creating SSH key (a passphrase is optional — Enter twice to skip):"
    ssh-keygen -t ed25519 -C "${USER}@${NEW_HOSTNAME}" -f ~/.ssh/id_ed25519 </dev/tty || return 1
  fi
  ssh-keygen -F github.com >/dev/null 2>&1 || ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null
  if ssh -o BatchMode=yes -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    ok "GitHub already accepts this key"; return 0
  fi
  echo
  echo "Add this key on GitHub → Settings → SSH and GPG keys → New SSH key:"
  echo "(copy with Ctrl+Shift+C)"
  echo; cat ~/.ssh/id_ed25519.pub; echo
  local i
  for i in 1 2 3; do
    read -r -p "Press Enter once it's added on GitHub... " _ </dev/tty
    if ssh -T git@github.com 2>&1 | tee /dev/stderr | grep -q "successfully authenticated"; then
      return 0
    fi
    warn "GitHub doesn't accept the key yet — check it was saved, then try again ($i/3)"
  done
  return 1
}

user_zsh() {
  if [[ ! -d ~/.oh-my-zsh ]]; then
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || return 1
  fi
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' ~/.zshrc
  add_line 'DEFAULT_USER=$USER' ~/.zshrc
  local zsh_path; zsh_path="$(command -v zsh)"
  [[ "$(getent passwd "$USER" | cut -d: -f7)" == "$zsh_path" ]] || sudo chsh -s "$zsh_path" "$USER"
}

user_fonts() {
  if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
    mkdir -p ~/.local/share/fonts
    curl -fL --retry 3 -o /tmp/nerdfont.zip \
      "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${NERD_FONT}.zip" &&
    unzip -oq /tmp/nerdfont.zip -d ~/.local/share/fonts && rm -f /tmp/nerdfont.zip &&
    fc-cache -f >/dev/null || return 1
  fi
  # Ptyxis (Ubuntu's default terminal)
  if gsettings list-schemas 2>/dev/null | grep -qx org.gnome.Ptyxis; then
    gsettings set org.gnome.Ptyxis use-system-font false 2>/dev/null
    gsettings set org.gnome.Ptyxis font-name "$TERMINAL_FONT" 2>/dev/null
  fi
  # GNOME Terminal (the purple one)
  if gsettings list-schemas 2>/dev/null | grep -qx org.gnome.Terminal.ProfilesList; then
    local p path
    p="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")"
    path="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$p/"
    gsettings set "$path" use-system-font false 2>/dev/null
    gsettings set "$path" font "$TERMINAL_FONT" 2>/dev/null
  fi
  # VS Code integrated terminal (only if no settings file yet)
  local vs=~/.config/Code/User/settings.json
  if [[ ! -f "$vs" ]]; then
    mkdir -p "$(dirname "$vs")"
    printf '{\n  "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font Mono"\n}\n' > "$vs"
  elif ! grep -q 'terminal.integrated.fontFamily' "$vs"; then
    warn "Set VS Code → Settings → 'terminal font family' to: JetBrainsMono Nerd Font Mono"
  fi
  return 0
}

user_brew() {
  if [[ ! -x "$BREW" ]]; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 1
  fi
  add_line "eval \"\$($BREW shellenv)\"" ~/.zshrc
  add_line "eval \"\$($BREW shellenv)\"" ~/.bashrc
  eval "$("$BREW" shellenv)"
}

user_toolbox() {
  [[ -n "$TOOLBOX_REPO" ]] || { warn "No toolbox repo given — skipped"; return 0; }
  if [[ ! -d "$TOOLBOX_DIR/.git" ]]; then
    mkdir -p "$(dirname "$TOOLBOX_DIR")" && git clone --recurse-submodules "$TOOLBOX_REPO" "$TOOLBOX_DIR" || return 1
  fi
  git -C "$TOOLBOX_DIR" submodule update --init --recursive || return 1
  [[ -f "$TOOLBOX_DIR/toolbox/setup.sh" ]] || { warn "toolbox/setup.sh not found in $TOOLBOX_DIR"; return 1; }
  ( cd "$TOOLBOX_DIR/toolbox" && bash ./setup.sh )
}

user_tflint() {
  have tflint && return 0
  brew install --cask terraform-linters/tap/tflint
}

user_gcloud_path() {
  have gcloud || { warn "gcloud not installed — skipped"; return 0; }
  local root; root="$(gcloud info --format='value(installation.sdk_root)' 2>/dev/null)"
  [[ -n "$root" ]] || return 1
  add_line "export PATH=\"$root/bin:\$PATH\"" ~/.zshrc
  export PATH="$root/bin:$PATH"
  gcloud components install gke-gcloud-auth-plugin --quiet
}

user_commitizen() {
  have node || brew install node || return 1
  npm config set prefix "$HOME/.npm-global" &&
  npm install -g commitizen cz-conventional-changelog || return 1
  printf '{\n  "path": "cz-conventional-changelog"\n}\n' > ~/.czrc
  # must come last in .zshrc so npm's `cz` wins over the toolbox's Python `cz`
  add_line 'export PATH="$HOME/.npm-global/bin:$PATH"' ~/.zshrc
}

user_no_autolock() {
  # Mac's own lock protects the VM; stop Ubuntu locking/blanking/suspending on idle
  gsettings set org.gnome.desktop.screensaver lock-enabled false &&
  gsettings set org.gnome.desktop.session idle-delay 0 &&
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' || return 1
  gsettings set org.gnome.desktop.screensaver ubuntu-lock-on-suspend false 2>/dev/null
  return 0
}

step "Remove old 'parallels' user"             remove_parallels_user
step "Disable auto screen lock / blank / sleep" user_no_autolock
step "Git name/email"                          user_git
step "SSH key for GitHub"                      user_ssh_key
step "zsh + Oh My Zsh (agnoster theme)"        user_zsh
step "Nerd Font + terminal fonts"              user_fonts
step "Homebrew"                                user_brew
step "Toolbox setup (brew bundle, plugins…)"   user_toolbox
step "tflint (terraform-linters tap, cask)"    user_tflint
step "gcloud PATH + gke-gcloud-auth-plugin"    user_gcloud_path
step "Commitizen (npm, with chore)"            user_commitizen

# =============================================================================
say "All done!"
if [[ ${#FAILED[@]} -gt 0 ]]; then
  printf '%s  Steps that failed (safe to re-run the script):%s\n' "$c_r" "$c_0"
  for f in "${FAILED[@]}"; do echo "   - $f"; done
fi
cat <<'EOF'

Next:
  • Log out and back in so zsh becomes your shell (then open a new Terminal).
  • Close old VS Code terminals (trash icon) and open new ones.
EOF
if [[ "$(systemd-detect-virt 2>/dev/null)" == "parallels" ]]; then
  echo "  • In Parallels on the Mac: Actions → Take Snapshot, so you can always roll back."
fi
