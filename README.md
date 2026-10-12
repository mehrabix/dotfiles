# dotfiles

My Linux (Ubuntu) dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's inside

| Package | Links into `$HOME` | Description |
| ------- | ------------------ | ----------- |
| `zsh`   | `.zshrc`, `.p10k.zsh` | Zsh + Oh My Zsh with the `robbyrussell` (macOS-style) arrow prompt |
| `bash`  | `.bashrc`, `.profile` | Bash fallback shell |
| `git`   | `.gitconfig` | Git config (credentials via `gh`) |
| `tmux`  | `.tmux.conf`, `.local/bin/tmux-sessionizer` | Tmux configuration (prefix `C-a`, vim-style pane switching, sessionizer) |
| `ptyxis` | `.local/share/org.gnome.Ptyxis/palettes` | macOS terminal palette (`macOS`); `install.sh` also sets login-shell, bold-is-bright, a block cursor and SF Mono |
| `nvim`  | `.config/nvim` | Neovim + [lazy.nvim](https://github.com/folke/lazy.nvim), Primeagen-style config (leader `space`, `<leader>pv` explorer) |
| `k9s`   | `.config/k9s` | [k9s](https://k9scli.io/) config with a `macos-dark` skin matching the terminal palette |

`macos-desktop/` is not a Stow package (nothing in it links into `$HOME`); it is
the optional desktop theming script described below.

`~/dotfiles/install.sh` also installs Oh My Zsh and the custom plugins/theme the
zsh config depends on. Those live in `~/.oh-my-zsh` and are **not** versioned
here — they are third-party repositories.

## Restore on a new machine

```sh
git clone https://github.com/mehrabix/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
```

The installer is idempotent — re-run it any time to relink after changes.

## macOS-style desktop

`macos-desktop/setup.sh` themes the GNOME desktop like macOS: the WhiteSur GTK
theme (dark, solid blue), icon theme and cursors, SF Pro from Apple, the User
Themes / Dash to Dock / Just Perfection extensions, a Sonoma wallpaper, and the
matching gsettings (dark blue accent, window buttons on the right, bottom dock,
clock on the right).

The dock is drawn by Dash to Dock and **rounded by the shell theme itself**
(`border-radius` on `.dash-background`), with no blur extension: Blur my Shell's
dash actor is built before the dock has an allocation, which left the dock
visibly glitched for a few seconds after login. Ubuntu's own dock is disabled —
Dash to Dock already draws it — and GNOME animations are turned off for a
snappier feel.

```sh
~/.dotfiles/macos-desktop/setup.sh              # user-level only
~/.dotfiles/macos-desktop/setup.sh --with-sudo  # + apt build deps + GDM login screen
```

It is idempotent and reversible, and needs `git`, `curl`, `unzip`, `7z`, `cpio`
plus (for the theme build) `sassc` and `imagemagick`. Log out and back in for the
shell theme and extensions — Wayland cannot restart GNOME Shell in place.

### Requirements

- `git`, and `sudo` if Stow is not installed yet (the script installs it via
  `apt`/`dnf`/`pacman`/`brew`).
- [fzf](https://github.com/junegunn/fzf) for the `fzf-tab` completion picker
  (optional; the plugin stays disabled without it).
- [SF Mono](https://developer.apple.com/fonts/) for the macOS-style terminal
  font (the Ptyxis profile uses *SF Mono 12*). The installer only *warns* if it
  is missing — drop the `.otf` files into `~/.local/share/fonts/` and run
  `fc-cache -f`. Any Menlo-like monospace font works if you change the
  `font-name` in `install.sh`.
- A [Nerd Font](https://www.nerdfonts.com/) in your terminal for the prompt and
  icons. Only needed if you switch back to the Powerlevel10k prompt.
- For Neovim: `ripgrep` (`rg`) for Telescope's live grep, and `node`/`npm` for
  the Mason-installed language servers. The first launch installs all plugins
  (lazy.nvim), Treesitter parsers and Mason tools, so it needs a network
  connection and takes a few minutes.

## Startup tweaks

`install.sh` masks Ubuntu's crash notifier
(`update-notifier-crash.{service,path}`), which otherwise costs about 5s of
session startup. Undo with `systemctl --user unmask update-notifier-crash.{service,path}`.

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
