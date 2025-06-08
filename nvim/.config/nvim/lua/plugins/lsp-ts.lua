return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tsserver = {}, -- TypeScript/JavaScript LSP
      },
    },
  },
  {
    "nvimtools/none-ls.nvim", -- Formatters and linters
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = vim.list_extend(opts.sources or {}, {
        nls.builtins.formatting.prettier, -- Prettier for TS/JS
        nls.builtins.diagnostics.eslint, -- ESLint diagnostics
      })
    end,
  },
}
