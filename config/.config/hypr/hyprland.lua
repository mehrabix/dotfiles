-- ─────────────────────────────────────────────────────────────────────────────
--  HYPRLAND · "MIDNIGHT GLASS"
--  A Ryoku-inspired, glassy, animated Hyprland rice.
--  GNOME stays installed and untouched; this is an additional session.
--  Config format: Hyprland 0.57+ Lua config.
-- ─────────────────────────────────────────────────────────────────────────────

local terminal    = "kitty"
local fileManager = "nautilus --new-window"
local browser     = "firefox"
local editor      = "code"
local launcher    = "wofi --show drun"
local scripts     = os.getenv("HOME") .. "/.config/hypr/scripts"

-- ─────────────────────────────────────────────────────────────────────────────
--  MONITORS
-- ─────────────────────────────────────────────────────────────────────────────
-- Matches the current GNOME Wayland layout exactly (from ~/.config/monitors.xml):
--   HDMI-1  -> 1920x1080 @ 60 Hz, at 0,0     (left)
--   eDP-1   -> 1920x1080 @ 60 Hz, at 1920,0  (right, PRIMARY)
-- Both at scale 1, total desktop 3840x1080.
hl.monitor({ output = "eDP-1",    mode = "preferred", position = "1920x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "0x0",    scale = 1 })

-- Fallback for any monitor not matched above (hot-plug safety net).
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- ─────────────────────────────────────────────────────────────────────────────
--  ENVIRONMENT
-- ─────────────────────────────────────────────────────────────────────────────
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "catppuccin-mocha-dark-cursors")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XDG_SESSION_TYPE", "wayland")

-- ─────────────────────────────────────────────────────────────────────────────
--  AUTOSTART
-- ─────────────────────────────────────────────────────────────────────────────
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hyprpaper &")
    hl.exec_cmd("waybar &")
    -- SwayNC is a D-Bus-activated systemd user service. Starting the service
    -- (instead of the bare binary) prevents a duplicate-instance race.
    hl.exec_cmd("systemctl --user start swaync.service")
    hl.exec_cmd("swayosd-server &")
    hl.exec_cmd("hypridle &")
    hl.exec_cmd("wl-paste --watch cliphist store &")
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  LOOK & FEEL
-- ─────────────────────────────────────────────────────────────────────────────
hl.config({
    general = {
        gaps_in     = 6,
        gaps_out    = 16,
        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(f2c879ee)", "rgba(e0705fee)" }, angle = 45 },
            inactive_border = "rgba(8b98a82e)",
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 18,
        rounding_power = 4.0,

        active_opacity   = 1.0,
        inactive_opacity = 0.96,

        dim_inactive = true,
        dim_strength = 0.06,

        shadow = {
            enabled      = true,
            range        = 28,
            render_power = 3,
            offset       = { 0, 8 },
            color        = 0x66000000,
            color_inactive = 0x33000000,
        },

        blur = {
            enabled            = true,
            size               = 8,
            passes             = 3,
            new_optimizations  = true,
            ignore_opacity     = true,
            xray               = false,
            noise              = 0.018,
            contrast           = 0.95,
            brightness         = 0.92,
            vibrancy           = 0.35,
            vibrancy_darkness  = 0.20,
            popups             = true,
            popups_ignorealpha = 0.2,
            input_methods      = true,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split  = true,
        smart_split     = true,
        smart_resizing  = true,
        -- special_scale_factor was removed: deprecated in Hyprland 0.57.
        -- The scratchpad now uses the default 1.0 scale.
    },

    misc = {
        force_default_wallpaper   = 0,
        disable_hyprland_logo     = true,
        disable_splash_rendering  = true,
        background_color          = 0x0b0f14,
        mouse_move_enables_dpms   = true,
        key_press_enables_dpms    = true,
        focus_on_activate         = true,
        animate_manual_resizes    = false,
        animate_mouse_windowdragging = false,
        enable_swallow            = true,
        swallow_regex             = "^(kitty)$",
        float_force_onscreen      = 2,
        new_float_force_onscreen  = 2,
    },

    input = {
        -- Same keyboard setup as the current GNOME session:
        --   US + Persian (Windows variant), switched with SUPER + Space.
        kb_layout    = "us,ir",
        kb_variant   = ",winkeys",
        kb_options   = "lv3:ralt_alt,grp:win_space_toggle",
        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll       = true,
            tap_to_click         = true,
            tap_and_drag         = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
        },
    },

    binds = {
        workspace_back_and_forth          = 1,
        allow_workspace_cycles            = true,
        hide_special_on_workspace_change  = true,
        focus_preferred_method            = 0,
        scroll_event_delay                = 200,
    },

    layers = {
        allow_new_top_layers_over_existing_fullscreen = true,
    },
})

-- ─────────────────────────────────────────────────────────────────────────────
--  ANIMATION CURVES
-- ─────────────────────────────────────────────────────────────────────────────
hl.curve("ryoku",    { type = "bezier", points = { { 0.16, 1 },    { 0.30, 1 } } })
hl.curve("ryokuIn",  { type = "bezier", points = { { 0.70, 0 },    { 0.84, 0 } } })
hl.curve("ryokuOut", { type = "bezier", points = { { 0.16, 1 },    { 0.30, 1 } } })
hl.curve("smooth",   { type = "bezier", points = { { 0.25, 0.10 }, { 0.25, 1 } } })
hl.curve("snap",     { type = "bezier", points = { { 0.15, 0 },    { 0.10, 1 } } })
hl.curve("softSpring", { type = "spring", mass = 1, stiffness = 190, damping = 22 })

hl.animation({ leaf = "global",         enabled = true, speed = 8,    bezier = "ryoku" })
hl.animation({ leaf = "windows",        enabled = true, speed = 5,    spring = "softSpring" })
hl.animation({ leaf = "windowsIn",      enabled = true, speed = 5,    spring = "softSpring", style = "popin 92%" })
hl.animation({ leaf = "windowsOut",     enabled = true, speed = 3,    bezier = "ryokuOut",   style = "popin 92%" })
hl.animation({ leaf = "windowsMove",    enabled = true, speed = 5,    spring = "softSpring" })
hl.animation({ leaf = "border",         enabled = true, speed = 6,    bezier = "ryoku" })
hl.animation({ leaf = "fade",           enabled = true, speed = 4,    bezier = "ryoku" })
hl.animation({ leaf = "fadeIn",         enabled = true, speed = 4,    bezier = "ryoku" })
hl.animation({ leaf = "fadeOut",        enabled = true, speed = 3,    bezier = "ryokuOut" })
hl.animation({ leaf = "layers",         enabled = true, speed = 4,    bezier = "ryoku" })
hl.animation({ leaf = "layersIn",       enabled = true, speed = 4,    bezier = "ryoku", style = "fade" })
hl.animation({ leaf = "layersOut",      enabled = true, speed = 3,    bezier = "ryokuOut", style = "fade" })
hl.animation({ leaf = "fadeLayersIn",   enabled = true, speed = 3,    bezier = "smooth" })
hl.animation({ leaf = "fadeLayersOut",  enabled = true, speed = 3,    bezier = "smooth" })
hl.animation({ leaf = "workspaces",     enabled = true, speed = 6,    bezier = "ryoku", style = "slidefade 20%" })
hl.animation({ leaf = "workspacesIn",   enabled = true, speed = 6,    bezier = "ryoku", style = "slidefade 20%" })
hl.animation({ leaf = "workspacesOut",  enabled = true, speed = 6,    bezier = "ryoku", style = "slidefade 20%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 6,  bezier = "ryoku", style = "slidefadevert 15%" })
hl.animation({ leaf = "zoomFactor",     enabled = true, speed = 7,    bezier = "snap" })

-- ─────────────────────────────────────────────────────────────────────────────
--  LAYER RULES  (glass blur for bar, launcher, notifications)
-- ─────────────────────────────────────────────────────────────────────────────
hl.layer_rule({ match = { namespace = "waybar" }, blur = true, ignore_alpha = 0.05 })
hl.layer_rule({ match = { namespace = "wofi" }, blur = true, ignore_alpha = 0.05 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0.05 })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true, ignore_alpha = 0.05 })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true, ignore_alpha = 0.05 })
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true, ignore_alpha = 0.05 })

-- ─────────────────────────────────────────────────────────────────────────────
--  WINDOW RULES
-- ─────────────────────────────────────────────────────────────────────────────
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name  = "float-pavucontrol",
    match = { class = "^(pavucontrol)$" },
    float = true, center = true, size = { 820, 560 },
})

hl.window_rule({
    name  = "float-blueman",
    match = { class = "^(blueman-manager)$" },
    float = true, center = true, size = { 900, 620 },
})

hl.window_rule({
    name  = "float-nwg-look",
    match = { class = "^(nwg-look)$" },
    float = true, center = true, size = { 920, 660 },
})

hl.window_rule({
    name  = "float-file-chooser",
    match = { class = "^(xdg-desktop-portal-gtk)$" },
    float = true, center = true, size = { 980, 680 },
})

hl.window_rule({
    name  = "kitty-opacity",
    match = { class = "^(kitty)$" },
    opacity = "0.97 0.93",
})

hl.window_rule({
    name  = "code-opacity",
    match = { class = "^(code|Code)$" },
    opacity = "0.99 0.95",
})

-- ─────────────────────────────────────────────────────────────────────────────
--  KEYBINDINGS
-- ─────────────────────────────────────────────────────────────────────────────
local mainMod = "SUPER"

local function b(keys, dispatcher, description, flags)
    flags = flags or {}
    flags.description = description
    hl.bind(keys, dispatcher, flags)
end

-- Apps
b(mainMod .. " + Return",  hl.dsp.exec_cmd(terminal),            "Terminal")
b(mainMod .. " + D",       hl.dsp.exec_cmd(launcher),            "Application launcher")
b(mainMod .. " + B",       hl.dsp.exec_cmd(browser),             "Browser")
b(mainMod .. " + E",       hl.dsp.exec_cmd(fileManager),         "File manager")
b(mainMod .. " + T",       hl.dsp.exec_cmd(terminal .. " -e btop"), "System monitor")
b(mainMod .. " + C",       hl.dsp.exec_cmd(editor),              "Code editor")
b(mainMod .. " + X",       hl.dsp.exec_cmd("gnome-text-editor"), "Text editor")
b(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("gnome-calculator"), "Calculator")

-- Window management
b(mainMod .. " + Q",          hl.dsp.window.close(),                       "Close window")
b(mainMod .. " + SHIFT + Q",  hl.dsp.window.kill(),                        "Kill window")
b(mainMod .. " + F",          hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }), "Fullscreen")
b(mainMod .. " + SHIFT + F",  hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }),  "Maximize")
-- NOTE: SUPER + Space is reserved for switching US/Persian keyboard layout
-- (same shortcut as GNOME), so floating/pin moved to SHIFT/CTRL variants.
b(mainMod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
b(mainMod .. " + CTRL + Space",  hl.dsp.window.pin(),                       "Pin window")
b(mainMod .. " + P",          hl.dsp.window.pseudo(),                       "Pseudo tile")
b(mainMod .. " + SHIFT + J",  hl.dsp.layout("togglesplit"),                 "Toggle split direction")
b(mainMod .. " + Tab",        hl.dsp.window.cycle_next(),                   "Next window")
b(mainMod .. " + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }),  "Previous window")

-- Focus
b(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }),  "Focus left")
b(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), "Focus right")
b(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }),    "Focus up")
b(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }),  "Focus down")
b(mainMod .. " + H",     hl.dsp.focus({ direction = "left" }),  "Focus left")
b(mainMod .. " + L",     hl.dsp.focus({ direction = "right" }), "Focus right")
b(mainMod .. " + K",     hl.dsp.focus({ direction = "up" }),    "Focus up")
b(mainMod .. " + J",     hl.dsp.focus({ direction = "down" }),  "Focus down")

-- Move windows
b(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }),  "Move window left")
b(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }), "Move window right")
b(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }),    "Move window up")
b(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }),  "Move window down")

-- Swap windows
b(mainMod .. " + CTRL + left",  hl.dsp.window.swap({ direction = "left" }),  "Swap window left")
b(mainMod .. " + CTRL + right", hl.dsp.window.swap({ direction = "right" }), "Swap window right")
b(mainMod .. " + CTRL + up",    hl.dsp.window.swap({ direction = "up" }),    "Swap window up")
b(mainMod .. " + CTRL + down",  hl.dsp.window.swap({ direction = "down" }),  "Swap window down")

-- Resize windows
b(mainMod .. " + ALT + left",  hl.dsp.window.resize({ x = -40, y = 0, relative = true }), "Shrink width")
b(mainMod .. " + ALT + right", hl.dsp.window.resize({ x = 40,  y = 0, relative = true }), "Grow width")
b(mainMod .. " + ALT + up",    hl.dsp.window.resize({ x = 0, y = -40, relative = true }), "Shrink height")
b(mainMod .. " + ALT + down",  hl.dsp.window.resize({ x = 0, y = 40,  relative = true }), "Grow height")

-- Workspaces
for i = 1, 10 do
    local key = i % 10
    b(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i }), "Workspace " .. i)
    b(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }),                          "Move window to workspace " .. i)
    b(mainMod .. " + CTRL + " .. key,      hl.dsp.window.move({ workspace = tostring(i) .. " silent" }),  "Send window to workspace " .. i)
end

-- Special workspace (scratchpad)
b(mainMod .. " + grave",         hl.dsp.workspace.toggle_special("magic"), "Toggle scratchpad")
b(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:magic" }), "Move window to scratchpad")

-- Groups (tabs)
b(mainMod .. " + G",         hl.dsp.group.toggle(), "Toggle group")
b(mainMod .. " + bracketright", hl.dsp.group.next(), "Next group window")
b(mainMod .. " + bracketleft",  hl.dsp.group.prev(), "Previous group window")

-- Mouse
b(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Next workspace")
b(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), "Previous workspace")
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Drag window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

-- Shell / system
b(mainMod .. " + V",          hl.dsp.exec_cmd(scripts .. "/clipboard.sh"),  "Clipboard history")
b(mainMod .. " + N",          hl.dsp.exec_cmd("swaync-client -t -sw"),      "Notification center")
b(mainMod .. " + SHIFT + N",  hl.dsp.exec_cmd("swaync-client -d -sw"),      "Toggle Do Not Disturb")
b(mainMod .. " + SHIFT + L",  hl.dsp.exec_cmd("loginctl lock-session"),     "Lock screen")
b(mainMod .. " + Escape",     hl.dsp.exec_cmd(scripts .. "/powermenu.sh"),  "Power menu")
b(mainMod .. " + SHIFT + E",  hl.dsp.exit(),                                "Exit Hyprland")
b(mainMod .. " + SHIFT + R",  hl.dsp.reload_config(),                       "Reload Hyprland config")
b(mainMod .. " + SHIFT + B",  hl.dsp.exec_cmd("pkill -SIGUSR2 waybar"),     "Reload Waybar")
b(mainMod .. " + SHIFT + T",  hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"),     "Toggle Waybar")
b(mainMod .. " + SHIFT + C",  hl.dsp.exec_cmd("swaync-client -R -rs"),      "Reload SwayNC")

-- Screenshots & color picker
b(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(scripts .. "/screenshot.sh region"), "Screenshot region")
b("Print",                   hl.dsp.exec_cmd(scripts .. "/screenshot.sh full"),   "Screenshot full screen")
b(mainMod .. " + Print",     hl.dsp.exec_cmd(scripts .. "/screenshot.sh window"), "Screenshot window")
b(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a"),                    "Pick color")

-- Media / hardware keys (with SwayOSD)
b("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume raise"), "Volume up",        { locked = true, repeating = true })
b("XF86AudioLowerVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume lower"), "Volume down",      { locked = true, repeating = true })
b("XF86AudioMute",         hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), "Mute output", { locked = true })
b("XF86AudioMicMute",      hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"),  "Mute microphone", { locked = true })
b("XF86MonBrightnessUp",   hl.dsp.exec_cmd("swayosd-client --brightness raise"), "Brightness up",      { locked = true, repeating = true })
b("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), "Brightness down",    { locked = true, repeating = true })
b("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),       "Next track",     { locked = true })
b("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),   "Previous track", { locked = true })
b("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), "Play / pause",   { locked = true })
b("XF86AudioPause",        hl.dsp.exec_cmd("playerctl play-pause"), "Play / pause",   { locked = true })
b("XF86Calculator",        hl.dsp.exec_cmd("gnome-calculator"),     "Calculator",     { locked = true })
b("XF86Search",            hl.dsp.exec_cmd(launcher),               "Launcher",       { locked = true })
b("XF86HomePage",          hl.dsp.exec_cmd(browser),                "Browser",        { locked = true })
