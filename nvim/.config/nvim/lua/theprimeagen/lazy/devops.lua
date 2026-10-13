-- DevOps / SRE toolchain layered on top of the Primeagen base config.
-- LSP servers live in lazy/lsp.lua; this file only adds the extra editor
-- tools (Mason CLI installs, Java) that do not come from an LSP server.
return {
  ---------------------------------------------------------------------------
  -- CLI tools, linters and formatters installed through Mason. Only tools not
  -- already pulled in as an LSP server dependency belong here.
  ---------------------------------------------------------------------------
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "yamlfmt", -- YAML
        "actionlint", -- GitHub Actions
        "shellcheck", -- shell
        "shfmt", -- shell formatting
        "stylua", -- lua formatting
        "prettier", -- js/ts/json formatting
        "markdownlint-cli2", -- Markdown
        "checkmake", -- Makefiles
        "dotenv-linter", -- .env
        "ruff", -- Python
        "regal", -- Rego
        "jq", -- data / query
        "yq", -- data / query
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Java (nvim-java). auto_install is off: it would otherwise download a
  -- ~200MB OpenJDK on startup. Turn it on when you actually want Java support.
  ---------------------------------------------------------------------------
  {
    "nvim-java/nvim-java",
    dependencies = {
      "nvim-java/lua-async-await",
      "nvim-java/nvim-java-test",
      "nvim-java/nvim-java-dap",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("java").setup({
        jdk = { auto_install = false },
      })
    end,
  },
}
