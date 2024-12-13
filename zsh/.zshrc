# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to the Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme configuration (Powerlevel10k)
ZSH_THEME="powerlevel10k/powerlevel10k"  # You can change this to another theme if you prefer

# Plugins: Enable zsh-autosuggestions, zsh-syntax-highlighting, and others
plugins=(
  git
  zsh-autosuggestions       # Autocomplete suggestions as you type
  zsh-syntax-highlighting   # Syntax highlighting
  tmux                      # Tmux integration (optional)
  autopep8                  # Python auto formatting (optional)
  command-not-found         # Command not found suggestions
)

# Set your default editor and VISUAL variable
export VISUAL=nvim
export EDITOR="$VISUAL"

# Enable case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Enable autocompletion (autoload compinit)
autoload -Uz compinit
compinit

# Enable auto-correction (optional)
setopt CORRECT

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Enable Powerlevel10k (if using this theme)
# The following line is optional if you are using a custom theme

# Enable zsh-autosuggestions for autocompletion
source $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Enable zsh-syntax-highlighting for syntax highlighting
source $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Tmux integration with Zsh
if [[ -n "$TMUX" ]]; then
  if [[ -z "$TMUX" ]]; then
    tmux attach || tmux new-session
  fi
fi

# Aliases
alias ll="ls -lah"
alias gs="git status"
alias gp="git push"
alias ..="cd .."
alias zshconfig="nvim ~/.zshrc"  # Quick access to .zshrc file

# Custom function for Tmux (if you use tmux)
function new_tmux_session() {
  tmux new-session -d -s $1
  tmux attach-session -t $1
}

# Custom prompt settings (Powerlevel10k or any other theme)
# Add Powerlevel10k configuration if needed (you can skip if using default theme)

# Enable history search as you type (using Up/Down arrows)
bindkey '^R' history-incremental-search-backward

# Optional: Customize the terminal color scheme (if using color schemes)
export TERM="xterm-256color"

# Optional: Enable virtualenvwrapper or Python virtualenv
# export WORKON_HOME=~/Envs
# source /usr/local/bin/virtualenvwrapper.sh

# End of .zshrc configuration

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
