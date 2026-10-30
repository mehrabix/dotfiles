# dotfiles

My Linux dotfiles (Arch and Debian/Ubuntu), managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's inside

| Package | Links into `$HOME` | Description |
| ------- | ------------------ | ----------- |
| `zsh`   | `.zshrc`, `.p10k.zsh` | Zsh + Oh My Zsh with the `robbyrussell` (macOS-style) arrow prompt |
| `bash`  | `.bashrc`, `.bash_profile`, `.profile` | Bash fallback shell |
| `git`   | `.gitconfig` | Git config (credentials via `gh`) |
| `tmux`  | `.tmux.conf`, `.local/bin/tmux-sessionizer` | Tmux configuration (prefix `C-b`, vim-style pane switching, sessionizer) |
| `ptyxis` | `.local/share/org.gnome.Ptyxis/palettes` | macOS terminal palette (`macOS`); `install.sh` also sets login-shell, bold-is-bright, a block cursor, SF Mono and background opacity |
| `nvim`  | `.config/nvim` | Neovim + [lazy.nvim](https://github.com/folke/lazy.nvim), Primeagen-style config (leader `space`, `<leader>pv` explorer) |

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
Use `--no-packages`, `--no-shell` or `--no-tweaks` to skip a stage.

## macOS-style desktop

`macos-desktop/setup.sh` themes GNOME like macOS: the WhiteSur GTK/shell theme,
icon theme and cursors, SF Pro + SF Mono from Apple, a Sonoma wallpaper, and the
matching gsettings (blue accent, window buttons on the right, bottom dock, clock
on the right).

```sh
~/.dotfiles/macos-desktop/setup.sh              # user-level only
~/.dotfiles/macos-desktop/setup.sh --solid      # opaque WhiteSur (no transparency)
~/.dotfiles/macos-desktop/setup.sh --with-sudo  # + build deps + GDM login screen
```

The dock is **Dash to Dock** on Arch (`gnome-shell-extension-dash-to-dock`) and
Ubuntu Dock on Ubuntu — the script detects whichever is present, pins it to
`HDMI-1`, and makes clicks behave like the macOS Dock (click minimizes, scroll
switches workspaces, middle-click launches). `DOCK_MONITOR=eDP-1` overrides the
display.

Keyboard layouts switch with Alt+Shift on **either side and in either order**
(bound through the shell's `switch-input-source`; `lv3:ralt_alt` keeps Right Alt
a plain Alt so it can take part in the chord).

Smaller familiarities: battery percentage and a weekday clock in the panel, a
top-left hot corner for the Overview (Mission Control), workspaces on every
display, and Super+E for the file manager.

### Transparency

GNOME cannot blur the windows *behind* another window — Mutter has no per-window
backdrop blur like Hyprland's `blur` rule. The closest equivalent is **Blur my
Shell**: the panel, dash, popups, Overview and app folders get a real blurred
backdrop, and its `applications` component makes every window translucent over
the blurred desktop, with rounded corners. Ptyxis gets its own background
opacity (0.85).

That is applied by default. `--solid` switches back to the plain
`WhiteSur-Dark-solid-*` theme and skips the Blur my Shell settings. GTK4 /
libadwaita apps get the same theme (and translucency) through
`~/.config/gtk-4.0`, which the script links to the WhiteSur CSS. Qt apps
(Zed, etc.) stay opaque unless a Qt style such as Kvantum is installed.

Extensions are only loaded at login — Wayland cannot restart GNOME Shell in
place, so log out and back in after running the script.

### Power menu (Log Out + Hibernate)

GNOME hides **Log Out** on single-user, single-session machines; the script sets
`org.gnome.shell always-show-log-out true` so it is always in the power menu.
**Hibernate** does not exist in GNOME 51's menu at all, so the script installs the
[Hibernate Power Menu](https://extensions.gnome.org/extension/10398/hibernate-power-menu/)
extension (Hibernate shown, Hybrid Sleep hidden by default).

The extension greys Hibernate out until the system can actually hibernate. On
Arch that needs a swap file at least as large as RAM and a resume path (the
[Arch wiki](https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate)
covers the details):

```sh
# 1. Swap file (16 GiB here; size it for your RAM)
sudo dd if=/dev/zero of=/swapfile bs=1M count=16384 status=progress
sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab

# 2. Physical offset of the swap file (ext4; btrfs uses btrfs inspect-internal)
sudo filefrag -v /swapfile | awk '$1=="0:" {print substr($4,1,length($4)-2)}'

# 3. UKI/systemd-boot: append resume= to the kernel cmdline. With GRUB use
#    GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/grub + grub-mkconfig instead.
echo "resume=UUID=$(findmnt -no UUID /) resume_offset=OFFSET" | sudo tee -a /etc/kernel/cmdline
# Add `resume` to HOOKS in /etc/mkinitcpio.conf, after `filesystems` and before `fsck`,
# then rebuild:
sudo mkinitcpio -P
```

`gdbus call --system --dest org.freedesktop.login1 \
--object-path /org/freedesktop/login1 \
--method org.freedesktop.login1.Manager.CanHibernate` should print `('yes',)`
(it may need a reboot after changing the kernel cmdline).

### Requirements

- `git`, and `sudo` if Stow is not installed yet (the script installs it via
  `pacman`/`apt`/`dnf`/`brew`).
- [fzf](https://github.com/junegunn/fzf) for the `fzf-tab` completion picker
  (optional; the plugin stays disabled without it).
- SF Pro and SF Mono are downloaded from Apple's DMGs by `setup.sh`. If that
  fails, drop the fonts into `~/.local/share/fonts/` and run `fc-cache -f`; any
  Menlo-like monospace font works if you change the `font-name` in `install.sh`.
- The theme build needs `git`, `curl`, `unzip`, `7z`, `cpio`, `python3`, `sassc`,
  `glib-compile-resources` and `imagemagick` (`--with-sudo` installs them).
- A [Nerd Font](https://www.nerdfonts.com/) in your terminal for the prompt and
  icons. Only needed if you switch back to the Powerlevel10k prompt.
- For Neovim: `ripgrep` (`rg`) for Telescope's live grep, `node`/`npm` for the
  Mason-installed language servers, and `tree-sitter-cli` to build the Treesitter
  parsers. The first launch installs plugins (lazy.nvim) and Mason tools, so it
  needs a network connection and takes a few minutes.

## System tweaks

`install.sh` applies a few AMD64 laptop tweaks, guarded so they only touch units
that exist on this distro: masks Ubuntu's crash notifier
(`update-notifier-crash.{service,path}`), skips Plymouth's boot splash
(`plymouth-quit-wait.service`, ~7s without disk encryption), drops
`vm.swappiness` to 10, disables a few services this laptop does not use
(printing, mobile broadband, dual-GPU switching, crash dumps), and turns off
sudo-rs's `pwfeedback` so sudo asks for the password silently. Each is reversible
— see the comments in `install.sh`. Use `--no-tweaks` to skip all of them.

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
cloud credentials (`~/.aws`), caches, and installed binaries (`~/.local/bin`).
