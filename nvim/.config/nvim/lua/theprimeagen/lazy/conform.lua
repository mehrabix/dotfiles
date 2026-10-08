return {
  "stevearc/conform.nvim",
  config = function()
    require("conform").setup({
      format_on_save = {
        timeout_ms = 5000,
        lsp_format = "fallback",
      },
      formatters_by_ft = {
        lua = { "stylua" },
        go = { "gofmt" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        json = { "prettier" },
        -- DevOps stack
        yaml = { "yamlfmt" },
        bash = { "shfmt" },
        sh = { "shfmt" },
        zsh = { "shfmt" },
      },
    })

    vim.keymap.set("n", "<leader>f", function()
      require("conform").format({ bufnr = 0 })
    end)
  end,
}
