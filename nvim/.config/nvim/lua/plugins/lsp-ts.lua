return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tsserver = {}, -- TypeScript/JavaScript LSP
      },
    },
  },
  -- Formatters and linters for TS/JS now run through conform.nvim and the
  -- ESLint language server (LazyVim's supported pipeline) instead of none-ls,
  -- which duplicated diagnostics now that the devops extras are enabled.
  { import = "lazyvim.plugins.extras.formatting.prettier" },
  { import = "lazyvim.plugins.extras.linting.eslint" },
}
