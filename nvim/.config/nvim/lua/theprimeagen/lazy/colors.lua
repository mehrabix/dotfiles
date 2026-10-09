function ColorMyPencils(color)
  color = color or "tokyonight"
  vim.cmd.colorscheme(color)
end

return {

  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = false },
        keywords = { italic = false },
        sidebars = "dark",
        floats = "dark",
      },
      -- Match the terminal: macOS Terminal's dark profile background.
      on_colors = function(colors)
        colors.bg = "#222425"
        colors.bg_dark = "#1b1d1e"
        colors.bg_float = "#222425"
        colors.bg_sidebar = "#1e2021"
        colors.bg_statusline = "#222425"
      end,
      -- tokyonight paints the 80-column guide (ColorColumn) near-black
      -- (#15161e). Against the macOS background that reads as a stray black
      -- bar, so use a subtle shade instead.
      on_highlights = function(hl)
        hl.ColorColumn = { bg = "#2b2d2f" }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      ColorMyPencils()
    end,
  },

}
