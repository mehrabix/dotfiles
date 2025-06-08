return {
  {
    "nvim-java/nvim-java",
    dependencies = {
      "nvim-java/lua-async-await",
      "nvim-java/nvim-java-core",
      "nvim-java/nvim-java-test",
      "nvim-java/nvim-java-dap",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("java").setup()
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
