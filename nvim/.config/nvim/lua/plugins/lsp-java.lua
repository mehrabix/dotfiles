return {
  {
    "nvim-java/nvim-java",
    dependencies = {
      "nvim-java/lua-async-await",
      -- NOTE: "nvim-java/nvim-java-core" is deliberately NOT listed here.
      -- It now resolves to v2.0.0, which rewrote the `java-core` API and dropped
      -- `system.get_arch()`. Because it shares the `java-core.*` module namespace
      -- it shadows the copy bundled inside nvim-java, and setup() dies with:
      --   base-spec.lua:151: attempt to call field 'get_arch' (a nil value)
      -- nvim-java still uses the v1 API, so it falls back to its own bundled copy.
      "nvim-java/nvim-java-test",
      "nvim-java/nvim-java-dap",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("java").setup({
        jdk = {
          -- Left off deliberately: nvim-java otherwise downloads a ~200MB OpenJDK
          -- on every startup. Flip to true once you actually want Java support.
          auto_install = false,
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        jdtls = {}, -- Java LSP via nvim-java
      },
    },
  },
}
