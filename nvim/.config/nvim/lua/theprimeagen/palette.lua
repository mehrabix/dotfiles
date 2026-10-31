-- The desktop colour system, vendored so Neovim matches kitty/alacritty,
-- yazi, cava, zathura and the GTK theme without depending on any theme tool.
-- Values are the muted blue/grey palette used across the machine: colour is
-- saved for the accent and for diagnostics, everything else is ink on slate.
local M = {
  bg = "#0f1417",
  bg_dark = "#0a0f12",
  bg_light = "#262b2e",
  bg_float = "#161c20",
  fg = "#dfe3e7",
  fg_dim = "#c0c8cd",
  fg_bright = "#bee9ff",
  muted = "#8a9297",
  accent = "#8ccff0",
  secondary = "#c7c2ea",
  steel = "#b4cad6",
  red = "#ffb4ab",
  yellow = "#c7c2ea",
  green = "#8ccff0",
  blue = "#b4cad6",
  cyan = "#c7c2ea",
  magenta = "#8ccff0",
  selection = "#004d65",
  selection_fg = "#dfe3e7",
  neutral = "#464364",
  border = "#262b2e",
}

-- Terminal palette (the same 16 colours as the kitty theme).
M.terminal = {
  M.bg,
  M.red,
  M.green,
  M.yellow,
  M.blue,
  M.magenta,
  M.cyan,
  M.fg,
  M.muted,
  M.red,
  M.green,
  M.yellow,
  M.blue,
  M.magenta,
  M.muted,
  M.fg_bright,
}

return M
