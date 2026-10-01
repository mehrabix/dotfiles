#!/usr/bin/env zsh
# ~/.zshrc — managed by GNU Stow (.dotfiles/zsh/.zshrc)
# Keep this file minimal. Every line here should do something you actually use.

# ─────────────────────────────────────────────────────────────
# Powerlevel10k instant prompt (must stay at the very top)
# ─────────────────────────────────────────────────────────────
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ─────────────────────────────────────────────────────────────
# Oh My Zsh
# ─────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"

# The install is owned by you and only contains harmless repo symlinks,
# so skip the noisy completion security check.
ZSH_DISABLE_COMPFIX="true"

ZSH_THEME="powerlevel10k/powerlevel10k"
# git: branch/status in the prompt. z: cd with tab completion.
# history-substring-search: type part of an old command, press Up to find it.
plugins=(git z history-substring-search)

source $ZSH/oh-my-zsh.sh

# ─────────────────────────────────────────────────────────────
# History
# ─────────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

# ─────────────────────────────────────────────────────────────
# Completion
# ─────────────────────────────────────────────────────────────
# Add zsh-completions to fpath before compinit, then run compinit once.
# -i is required: without it compinit prompts on "insecure directories"
# and blocks the shell.
[[ -r $ZSH/custom/plugins/zsh-completions/zsh-completions.plugin.zsh ]] && \
  source $ZSH/custom/plugins/zsh-completions/zsh-completions.plugin.zsh

# Rebuild the dump automatically if it is missing or older than 24 hours.
# -i is required: without it compinit stops on "insecure directories" and blocks.
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit -i -d "$HOME/.zcompdump"
else
  rm -f "$HOME/.zcompdump"
  compinit -i -d "$HOME/.zcompdump"
fi

# Menu selection + case-insensitive completion.
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
setopt AUTO_MENU COMPLETE_IN_WORD ALWAYS_TO_END
unsetopt MENU_COMPLETE NO_ALWAYS_LAST_PROMPT

# ─────────────────────────────────────────────────────────────
# Plugins
# ─────────────────────────────────────────────────────────────
# fzf-tab: nicer completion picker. Needs compinit to have run.
if (( $+commands[fzf] )); then
  [[ -r $ZSH/custom/plugins/fzf-tab/fzf-tab.plugin.zsh ]] && \
    source $ZSH/custom/plugins/fzf-tab/fzf-tab.plugin.zsh
  zstyle ':fzf-tab:*' switch-group 'ctrl-k' 'ctrl-j'
  zstyle ':fzf-tab:*' fzf-command fzf
else
  # Without fzf, loading fzf-tab makes Tab appear to do nothing.
  disable -r fzf-tab 2>/dev/null
fi

# zsh-autosuggestions: inline grey ghost text from history.
[[ -r $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# zsh-syntax-highlighting MUST be the last plugin sourced: it hooks into the
# ZLE widgets defined by everything above, and does nothing useful if those
# widgets do not exist yet.
(( $+functions[zle-line-pre-redraw] )) || {
  [[ -r $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
}
# 'histnumbers' is intentionally left out: zsh-syntax-highlighting 0.8.0
# disables it and prints "warning: disabling the 'histnumbers' highlight"
# on every shell start.
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)

# ─────────────────────────────────────────────────────────────
# Aliases
# ─────────────────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias ldot='ls -ld .*'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ..='cd ..'
alias ...='cd ../..'
alias -- -='cd -'
alias du='du -h'
alias df='df -h'
alias free='free -h'
alias mkdir='mkdir -pv'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ping='ping -c 5'
alias fd='fdfind'

# ─────────────────────────────────────────────────────────────
# Options
# ─────────────────────────────────────────────────────────────
setopt AUTO_CD INTERACTIVE_COMMENTS NO_CASE_GLOB EXTENDED_GLOB
setopt NO_FLOW_CONTROL               # so Ctrl+S / Ctrl+Q work in a terminal
setopt NO_BEEP                       # no terminal bell
unsetopt BEEP                        # same, for zsh's own bell

# ─────────────────────────────────────────────────────────────
# Key bindings
# ─────────────────────────────────────────────────────────────
# emacs-style keys, which is what the history-substring-search plugin and
# fzf-tab expect. Ctrl+Left/Right move by word, Ctrl+Up/Down scroll history.
bindkey -e
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5A' history-substring-search-up
bindkey '^[[1;5B' history-substring-search-down
bindkey '^H'   backward-kill-word     # Ctrl+Backspace deletes a word
bindkey '^[[H' backward-kill-word     # same, for terminals that send this

# ─────────────────────────────────────────────────────────────
# Bracketed paste
# ─────────────────────────────────────────────────────────────
# This zsh build (5.9-8ubuntu3) is compiled WITHOUT ZLE bracketed-paste
# support, so terminals that send \e[200~ / \e[201~ (Ubuntu's ptyxis does)
# get those markers inserted as literal text, which produced errors like:
#   zsh: bad pattern: ^[[200~sudo
# Binding the markers to a no-op widget makes ZLE swallow them, so pasted
# text arrives clean. Newlines still behave normally — press Enter to run.
_zsh_bp_noop() { : }
zle -N _zsh_bp_noop 2>/dev/null
bindkey $'\e\[200~' _zsh_bp_noop 2>/dev/null
bindkey $'\e\[201~' _zsh_bp_noop 2>/dev/null
bindkey $'\e\[?2004h' _zsh_bp_noop 2>/dev/null
bindkey $'\e\[?2004l' _zsh_bp_noop 2>/dev/null

# ─────────────────────────────────────────────────────────────
# Tooling (nvm, PATH)
# ─────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"

# Put the default node toolchain on PATH immediately. This is just one PATH
# entry, so it costs nothing, but it makes node, npm, npx AND global npm
# binaries such as cmdc work in every shell — no lazy aliases to get stuck.
if [[ -d "$NVM_DIR/versions/node" ]]; then
  _node_bin="$NVM_DIR/versions/node/$(command ls -1 "$NVM_DIR/versions/node" | sort -V | tail -n1)/bin"
  [[ -d "$_node_bin" ]] && export PATH="$_node_bin:$PATH"
  unset _node_bin
fi

# nvm itself (sourcing nvm.sh costs ~180ms) is loaded only when you ask for it.
nvm() {
  unfunction nvm
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
  nvm "$@"
}

# ─────────────────────────────────────────────────────────────
# tmux
# ─────────────────────────────────────────────────────────────
# Your normal terminal is left alone on purpose so Tab completion and text
# selection behave predictably. Start tmux only when you want it.
t() {
  if [[ -z "$TMUX" ]]; then
    tmux attach-session -t main 2>/dev/null || tmux new-session -s main
  else
    echo "Already inside tmux."
  fi
}

# ─────────────────────────────────────────────────────────────
# Powerlevel10k config
# ─────────────────────────────────────────────────────────────
[[ -r ~/.p10k.zsh ]] && source ~/.p10k.zsh
