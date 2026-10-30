# dotfiles

My Linux dotfiles (Arch and Debian/Ubuntu), managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's inside

| Package | Links into `$HOME` | Description |
| ------- | ------------------ | ----------- |
| `zsh`   | `.zshrc`, `.p10k.zsh` | Zsh + Oh My Zsh with the `robbyrussell` arrow prompt |
| `bash`  | `.bashrc`, `.bash_profile`, `.profile` | Bash fallback shell |
| `git`   | `.gitconfig` | Git config (credentials via `gh`) |
| `tmux`  | `.tmux.conf`, `.local/bin/tmux-sessionizer` | Tmux configuration (prefix `C-b`, vim-style pane switching, sessionizer) |
| `ptyxis` | `.local/share/org.gnome.Ptyxis/palettes` | Terminal palette; `install.sh` also sets login-shell, bold-is-bright, a block cursor, SF Mono and background opacity |
| `nvim`  | `.config/nvim` | Neovim + [lazy.nvim](https://github.com/folke/lazy.nvim), Primeagen-style config (leader `space`, `<leader>pv` explorer) |
| `config` | `.config/*`, `.npmrc`, `.local/bin` | Terminal, app and desktop config: alacritty/ghostty/kitty/fish/starship, btop/cava/fastfetch/neofetch/yazi/zathura, VLC, Vesktop/Equibop, GTK/KDE/Qt, monitors, wallpapers, systemd user units, WirePlumber Bluetooth codecs |

`dracula-desktop/` is not a Stow package (nothing in it links into `$HOME`); it
is the desktop theming script described below.

`dconf/gnome.ini` is the captured desktop settings (theme, extensions,
keybindings, monitor layout). It cannot be stowed, so `install.sh` replays it
with `dconf load`.

`~/dotfiles/install.sh` also installs Oh My Zsh and the custom plugins/theme the
zsh config depends on. Those live in `~/.oh-my-zsh` and are **not** versioned
here — they are third-party repositories.

## Restore on a new machine

```sh
git clone https://github.com/mehrabix/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
```

That one command restores everything: packages, Oh My Zsh + plugins, every
stowed config, the GNOME/dconf settings, the Dracula glass theme (icons, cursor,
fonts, extensions, power menu) and the system tweaks. Log out and back in
afterwards so GNOME loads the extensions.

The installer is idempotent — re-run it any time to pick up new commits.
Use `--no-packages`, `--no-shell`, `--no-tweaks`, `--no-dconf` or
`--no-desktop` to skip a stage.

### Syncing changes back

The repo is the source of truth. After editing a config on this machine:

```sh
~/.dotfiles/sync.sh          # copy live config into config/ + dconf/gnome.ini
cd ~/.dotfiles && git diff   # review
git add -A && git commit -m "..." && git push
```

`sync.sh` has the list of managed paths at the top — add a new one there and it
is captured from then on. Secrets are never copied: browser profiles, keyrings,
gh tokens, Docker/Kubernetes credentials, SSH/GPG keys, caches, histories and
session state are excluded.

## Desktop look (Dracula + glass)

`dracula-desktop/setup.sh` gives GNOME a translucent, purple-tinted look:

- **Dracula GTK** for GTK3 and GTK4/libadwaita apps. It is a colour theme, so
  window controls stay GNOME's own (symbolic, right side) instead of another theme's
  traffic lights.
- **Tela-circle-dracula** icons and the **Catppuccin Mocha** cursor.
- GNOME's own shell theme, with the panel, dash and popups blurred by **Blur my
  Shell** — no WhiteSur shell theme and no dock rounding hacks.
- Purple accent colour, dark scheme, SF Pro / SF Mono.

```sh
~/.dotfiles/dracula-desktop/setup.sh              # Dracula + glass
~/.dotfiles/dracula-desktop/setup.sh --solid      # same, no blur/transparency
~/.dotfiles/dracula-desktop/setup.sh --whitesur   # the old WhiteSur theme
~/.dotfiles/dracula-desktop/setup.sh --with-sudo  # + build deps + GDM login screen

`install.sh` runs the first form for you unless you pass `--no-desktop`.
```

The dock is **Dash to Dock** on Arch (`gnome-shell-extension-dash-to-dock`) and
Ubuntu Dock on Ubuntu — the script detects whichever is present, pins it to
`HDMI-1`, and makes clicks behave like a dock (click minimizes, scroll switches
workspaces, middle-click launches). `DOCK_MONITOR=eDP-1` overrides the display.

Keyboard layouts switch with Alt+Shift on **either side and in either order**
(bound through the shell's `switch-input-source`; `lv3:ralt_alt` keeps Right Alt
a plain Alt so it can take part in the chord).

Smaller familiarities: battery percentage and a weekday clock in the panel, a
top-left hot corner for the Overview, workspaces on every display, and Super+E
for the file manager.

### Transparency

GNOME cannot blur the windows *behind* another window — Mutter has no per-window
backdrop blur like Hyprland's `blur` rule. The closest equivalent is **Blur my
Shell**: the panel, dash, popups, Overview and app folders get a real blurred
backdrop, and its `applications` component makes every window translucent over
the blurred desktop. App opacity is 180/255; Ptyxis gets its own background
opacity (0.85).

Corner rounding is left to the GTK theme. Blur my Shell clipping windows at a
different radius drew a second arc over the theme's rounded corners, so its own
rounding is disabled (`rounded-corners 3`).

`--solid` skips the Blur my Shell settings entirely. GTK4 / libadwaita apps get
the same theme through `~/.config/gtk-4.0` (and `~/.config/assets` for
Dracula's CSS). Qt apps (Zed, etc.) stay opaque unless a Qt style such as
Kvantum is installed.

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
- `curl`, `tar`, `gjs` and `unzip` for the Dracula/Tela downloads and the GNOME
  extension settings.
- SF Pro and SF Mono are downloaded from Apple's DMGs by `setup.sh`. If that
  fails, drop the fonts into `~/.local/share/fonts/` and run `fc-cache -f`; any
  Menlo-like monospace font works if you change the `font-name` in `install.sh`.
- `--whitesur` additionally needs `sassc`, `glib-compile-resources`, `xmllint`,
  `imagemagick`, `7z` and `cpio` to build WhiteSur (`--with-sudo` installs them).
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

## Gaming (Steam)

This laptop is a Dell Inspiron 5567: 2-core / 4-thread i7-7500U (15 W), 15 GB
RAM, Intel HD 620 plus an AMD Radeon R5 M445 (4 GB, `iceland`/GCN 4, PCIe 3.0
x4). The dGPU renders, the iGPU drives both 1080p60 panels. Games run through a
small wrapper so no game has to be configured twice.

### `game-run`

`~/.local/bin/game-run` is the launch prefix for every Steam title. It:

- wakes the dGPU (amdgpu runtime-suspends it when idle) and waits for its render
  node,
- exports `DRI_PRIME=pci-0000_01_00_0` so GL/VA-API land on the Radeon,
- exports `VK_LOADER_DRIVERS_SELECT='*radeon*'` so Vulkan (and therefore
  DXVK/VKD3D) never falls back to the HD 620,
- turns on RADV's pipeline library and a 6 GB shader cache to kill first-run
  compile stutter, plus `mesa_glthread` for GL games,
- pins DXVK/VKD3D state caches to the SSD,
- `exec`s `gamemoderun "$@"` (governor, I/O priority, `SCHED_ISO` reaper).

`~/.config/gamemode.ini` leaves the CPU governor alone: power-profiles-daemon's
"performance" profile drives intel_pstate through EPP=performance and
max_perf_pct=100, while pinning the governor itself to `performance` holds every
core at 3.5 GHz and just reaches the 92 °C throttle wall sooner. GameMode still
does the useful parts (I/O priority, `SCHED_ISO` reaper).

### Which monitor

Games always land on the Samsung 27" (`HDMI-1`, 1920×1080@60):

- `monitors.xml` marks it primary and GNOME places new windows there; XWayland
  and Wine both use the primary output for fullscreen.
- Before launching, `game-run` checks the live primary with `gdctl` and
  re-applies the same layout with `HDMI-1` primary if a hotplug or a GNOME
  update moved it back to the laptop panel (positions are read from `xrandr`,
  so nothing gets reshuffled).
- `GAME_MONITOR=DP-1 game-run …` targets a different output by hand.

The laptop panel stays on as the second screen: Samsung at 0–1920, eDP-1 at
1920–3840.

### Steam launch options

```
CS2       /home/ahmad/.local/bin/game-run %command% -fullscreen -novid -nojoy -high +fps_max 60
Asphalt   /home/ahmad/.local/bin/game-run %command%
```

They live in `userdata/<id>/config/localconfig.vdf` and survive restarts; Steam
rewrites that file, so re-check after a Steam update. To make a different game
use the dGPU, give it the Asphalt line.

### CS2

`cs2_video.txt` is set to exclusive fullscreen (not borderless), vsync off, FSR
on, low/medium detail, and `fps_max 60` in `cs2_machine_convars.vcfg`. Capping
at the panel refresh keeps the 15 W CPU from throttling: 400 fps just cooks it
and adds frame-time variance. On this hardware ~60 fps at 1080p is the realistic
target; if it dips, drop the render resolution via FSR before touching anything
else.

### Asphalt Legends

DX12 through VKD3D-Proton, which is 70–100 % slower than native DX12 on GCN 4.
`-dx11` (add it after `%command%`) can help but crashes on some updates.
`install.sh` already installs the 32-bit Vulkan/GameMode stack on Arch; by hand:

```sh
sudo pacman -S --needed lib32-vulkan-radeon lib32-vulkan-intel lib32-gamemode lib32-mangohud
```

### Thermals are the real ceiling

Sustained 4-thread load pins the package at 92–93 °C within ~15 s, the fan
hits ~5500 RPM, and the CPU clamps to ~3.0 GHz. No kernel throttle events are
logged — this is the firmware doing its job on 9-year-old thermal paste. If
frames degrade the longer you play, repaste the cooler and clean the fan;
nothing in software fixes that. Play on AC (the power profile is already
`performance`), and keep the lid open with the vents clear.

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
