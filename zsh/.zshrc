# Add deno completions to search path
if [[ ":$FPATH:" != *":/home/aenima/.zsh/completions:"* ]]; then export FPATH="/home/aenima/.zsh/completions:$FPATH"; fi
# Path to your Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set the theme to Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# Enable/Disable various features
ENABLE_CORRECTION="true"  # Enable command auto-correction
DISABLE_AUTO_TITLE="false" # Enable auto-setting terminal title

# Plugin configuration
plugins=(
  git
  zsh-autosuggestions       # Autocomplete suggestions as you type
  zsh-syntax-highlighting   # Syntax highlighting for better visibility
  tmux                      # Tmux integration
  autopep8                  # Python auto formatting
  command-not-found         # Suggestions for unrecognized commands
  npm                       # NPM commands for Node.js integration
  history-substring-search  # History search enhancements
  fzf                        # Fuzzy finder integration
)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Paths
export PATH="/home/linuxbrew/.linuxbrew/opt/node@23/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/opt/util-linux/bin:$PATH"
export PATH="/usr/local/opt/util-linux/sbin:$PATH"
export PNPM_HOME="$HOME/.pnpm"
export PATH="$PNPM_HOME:$PATH"
export PATH="$HOME/.pnpm/bin:$PATH"

# Aliases
alias ll="ls -lah"
alias gs="git status"
alias gp="git push"
alias ..="cd .."
alias zshconfig="nvim ~/.zshrc"  # Quick access to .zshrc file
alias rg="rg --hidden --glob '!*.git/'"

# History and search settings
bindkey '^R' history-incremental-search-backward

# Enable case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Initialize completion
autoload -Uz compinit
compinit

# Set default editor and VISUAL variable
export VISUAL=nvim
export EDITOR="$VISUAL"

# Tmux session creation function (optional)
function new_tmux_session() {
  tmux new-session -d -s $1
  tmux attach-session -t $1
}

# Optional: Enable virtualenvwrapper for Python virtualenv
# export WORKON_HOME=~/Envs
# source /usr/local/bin/virtualenvwrapper.sh

# Rust configuration (Add Cargo to PATH)
if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"  # Sourcing Rust environment variables
fi

# Powerlevel10k configuration (optional)
# Ensure that if you have a custom configuration file for Powerlevel10k, source it.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
typeset -g POWERLEVEL9K_INSTANT_PROMPT='%~ %#'

# Custom prompt with clean look (no username, no multiline)
# The Powerlevel10k theme will manage the prompt appearance
# Customization is handled via `~/.p10k.zsh`
PROMPT='%~ %# '  # Shows the current directory and prompt symbol without color

# Enable zsh-autosuggestions plugin
source $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Enable zsh-syntax-highlighting plugin
source $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Optional: Set terminal to support 256 colors
export TERM="xterm-256color"

# Source any additional custom configurations
# source $ZSH_CUSTOM/aliases.zsh
#
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
export PATH="/home/linuxbrew/.linuxbrew/sbin:$PATH"

alias rg="rg --hidden --glob '.zshrc.git/'"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export PATH="$(npm config get prefix)/bin:$PATH"

. "$HOME/.cargo/env"


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
. "/home/aenima/.deno/env"