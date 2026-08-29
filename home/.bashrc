# ~/.bashrc: portable interactive shell config managed by ~/.dotfiles.

# If not running interactively, don't do anything.
case $- in
    *i*) ;;
      *) return ;;
esac

# History.
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend
shopt -s checkwinsize

# Color support and common aliases.
if [ -x /usr/bin/dircolors ]; then
    test -r "$HOME/.dircolors" && eval "$(dircolors -b "$HOME/.dircolors")" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Bash completion.
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# conda (lazy: only initialised on first use).
export CONDA_ROOT="$HOME/miniconda3"
export PATH="$CONDA_ROOT/condabin:$PATH"

__load_conda() {
    unset -f conda __load_conda

    if [ -f "$CONDA_ROOT/etc/profile.d/conda.sh" ]; then
        . "$CONDA_ROOT/etc/profile.d/conda.sh"
    elif [ -x "$CONDA_ROOT/bin/conda" ]; then
        eval "$("$CONDA_ROOT/bin/conda" shell.bash hook 2> /dev/null)"
    else
        export PATH="$CONDA_ROOT/bin:$PATH"
    fi
}

conda() {
    __load_conda
    conda "$@"
}

# nvm (lazy: only initialised on first use).
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

# PATH.
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# yazi: `y` opens yazi and cd's into the dir you quit from.
y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")" || return
    command yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd" || return
    fi
    command rm -f -- "$tmp"
}

# Make plain `yazi` also cd into the directory you quit from.
# Use `command yazi` if you want the raw binary without the cd.
alias yazi='y'

# Machine-local overrides: secrets, proxy, VPN, host-specific PATH.
[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
