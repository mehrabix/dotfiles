# dotfiles

My Linux (Ubuntu) dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's inside

| Package | Links into `$HOME` | Description |
| ------- | ------------------ | ----------- |
| `zsh`   | `.zshrc`, `.p10k.zsh` | Zsh + [Powerlevel10k](https://github.com/romkatv/powerlevel10k) prompt (lean, one-line, devops flavored) |
| `bash`  | `.bashrc`, `.profile` | Bash fallback shell |
| `git`   | `.gitconfig` | Git config (credentials via `gh`) |
| `tmux`  | `.tmux.conf` | Tmux configuration |
| `nvim`  | `.config/nvim` | Neovim (LazyVim) configuration |

`~/dotfiles/install.sh` also installs Oh My Zsh and the custom plugins/theme the
zsh config depends on. Those live in `~/.oh-my-zsh` and are **not** versioned
here — they are third-party repositories.

## Restore on a new machine

```sh
git clone https://github.com/mehrabix/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
```

The installer is idempotent — re-run it any time to relink after changes.

### Requirements

- `git`, and `sudo` if Stow is not installed yet (the script installs it via
  `apt`/`dnf`/`pacman`/`brew`).
- [fzf](https://github.com/junegunn/fzf) for the `fzf-tab` completion picker
  (optional; the plugin stays disabled without it).
- A [Nerd Font](https://www.nerdfonts.com/) in your terminal for the prompt and
  icons.

## How it works

Each top-level directory is a Stow package whose tree mirrors `$HOME`:

```
zsh/.zshrc   ->  ~/.zshrc
nvim/.config/nvim  ->  ~/.config/nvim
```

To add a file, put it under the matching package and re-run `install.sh` (or
`stow <package>`). To preview changes without touching anything:

```sh
stow --simulate --verbose zsh
```

## Not included

Secrets and machine state are intentionally out of the repo: SSH and GPG keys,
cloud credentials (`~/.aws`, `~/.kube`, `~/.ansible`), caches, and installed
binaries (`~/.local/bin`).
