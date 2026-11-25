#!/bin/zsh

# ─── Environment & PATH ──────────────────────────────────────────────
BREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
export PNPM_HOME="$HOME/Library/pnpm"

typeset -U path
path=(
    "$HOME/.bun/bin"
    "$HOME/.kimi-code/bin"
    "$PNPM_HOME"
    "$HOME/.local/bin"
    "$BREW_PREFIX/bin"
    "$BREW_PREFIX/sbin"
    $path
)

# ─── Prompt & Completions ────────────────────────────────────────────
eval "$(starship init zsh)"

[[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

[[ -d "$BREW_PREFIX/share/zsh-completions" ]] && \
    fpath=("$BREW_PREFIX/share/zsh-completions" $fpath)

autoload -Uz compinit && compinit
command -v zmx >/dev/null && eval "$(zmx completions zsh)"

# Substring + case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=*'

# ─── History ─────────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# ─── Tool Integrations ───────────────────────────────────────────────
command -v fzf >/dev/null && eval "$(fzf --zsh)"
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
if command -v fd >/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

eval "$(zoxide init zsh)"
command -v fnm >/dev/null && eval "$(fnm env --use-on-cd --shell zsh)"
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# ─── zmx ─────────────────────────────────────────────────────────────
# Keep Kitty identity current after reattaching a zmx session in another pane.
typeset -U _zmx_tracked_env
_zmx_tracked_env=( ${(s:,:)ZMX_TRACK_ENV} KITTY_LISTEN_ON KITTY_WINDOW_ID )
export ZMX_TRACK_ENV="${(j:,:)_zmx_tracked_env}"
unset _zmx_tracked_env

function zmx-attach() {
    if [[ -z "${1:-}" ]]; then
        print -u2 'usage: zmx-attach <session>'
        return 2
    fi
    env -u ZMX_SESSION zmx attach "$1"
}

function zmx-list() {
    zmx list --short
}

# ─── Functions & Aliases ─────────────────────────────────────────────
function set-ssh-key() {
    local key="$HOME/.ssh/$1"
    if [[ ! -f "$key" ]]; then
        echo "Key not found: $key" >&2
        echo "Available keys:" >&2
        ls ~/.ssh/*.pub 2>/dev/null | sed 's/.*\//  /; s/\.pub$//' >&2
        return 1
    fi
    ssh-add -D 2>/dev/null
    ssh-add "$key"
    echo "Active SSH key: $1"
}

alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias lt='eza --tree --icons --level=2'
alias cat='bat'
alias find='fd'
alias grep='rg'
alias top='btop'
alias lg='lazygit'

# ─── Syntax Highlighting (must be loaded last) ───────────────────────
[[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
