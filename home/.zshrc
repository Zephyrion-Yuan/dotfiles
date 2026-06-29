typeset -U path PATH

# ── conda (lazy: only initialised on first use) ─────────────────────────────
export CONDA_ROOT="$HOME/miniconda3"
export PATH="$CONDA_ROOT/condabin:$PATH"

__load_conda() {
    unset -f conda __load_conda

    if [ -f "$CONDA_ROOT/etc/profile.d/conda.sh" ]; then
        . "$CONDA_ROOT/etc/profile.d/conda.sh"
    elif [ -x "$CONDA_ROOT/bin/conda" ]; then
        eval "$("$CONDA_ROOT/bin/conda" shell.zsh hook 2> /dev/null)"
    else
        export PATH="$CONDA_ROOT/bin:$PATH"
    fi
}

conda() {
    __load_conda
    conda "$@"
}

# ── nvm (lazy: only initialised on first use) ───────────────────────────────
export NVM_DIR="$HOME/.nvm"

__load_nvm() {
    unset -f nvm node npm npx yarn pnpm corepack __load_nvm

    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
}

nvm()      { __load_nvm; nvm "$@"; }
node()     { __load_nvm; node "$@"; }
npm()      { __load_nvm; npm "$@"; }
npx()      { __load_nvm; npx "$@"; }
yarn()     { __load_nvm; yarn "$@"; }
pnpm()     { __load_nvm; pnpm "$@"; }
corepack() { __load_nvm; corepack "$@"; }

# ── PATH ────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"   # npm global prefix

# ── yazi: `y` opens yazi and cd's into the dir you quit from ─────────────────
function y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  command yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  command rm -f -- "$tmp"
}
# Make plain `yazi` also cd into the directory you quit from.
# (Use `command yazi` if you ever want the raw binary without the cd.)
alias yazi='y'

# ── Machine-local overrides (secrets, proxy, host-specific) — NOT in git ─────
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
