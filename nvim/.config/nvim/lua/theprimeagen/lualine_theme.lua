-- lualine theme for the colorless colourscheme. lualine's "auto" would find
-- no theme called colorless and silently fall back to gruvbox, so give it the
-- palette directly.
local p = require("theprimeagen.palette")

local function mode(accent)
  local a = { fg = p.bg, bg = accent, gui = "bold" }
  local b = { fg = p.fg, bg = p.bg_light }
  local c = { fg = p.muted, bg = p.bg }
  return { a = a, b = b, c = c, x = b, y = c, z = c }
end

return {
  normal = mode(p.accent),
  insert = mode(p.green),
  visual = mode(p.secondary),
  replace = mode(p.red),
  command = mode(p.steel),
  terminal = mode(p.steel),
  inactive = {
    a = { fg = p.muted, bg = p.bg },
    b = { fg = p.muted, bg = p.bg },
    c = { fg = p.muted, bg = p.bg },
  },
}
