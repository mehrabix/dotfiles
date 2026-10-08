return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    init = function()
      local parsers = {
        -- core languages
        "lua",
        "vim",
        "vimdoc",
        "query",
        "javascript",
        "typescript",
        "tsx",
        "html",
        "css",
        "json",
        "gitignore",
        "go",
        -- devops stack
        "bash",
        "dockerfile",
        "gitattributes",
        "gitcommit",
        "git_config",
        "graphql",
        "hcl",
        "helm",
        "ini",
        "jq",
        "json5",
        "make",
        "markdown",
        "markdown_inline",
        "nginx",
        "pem",
        "promql",
        "properties",
        "python",
        "rego",
        "sql",
        "ssh_config",
        "terraform",
        "yaml",
        "cue",
      }

      local group = vim.api.nvim_create_augroup("ThePrimeagenTreesitter", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
        group = group,
        callback = function()
          if vim.bo.buftype ~= "" then
            return
          end
          pcall(vim.treesitter.start, 0)
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "VeryLazy",
        once = true,
        callback = function()
          require("nvim-treesitter").install(parsers)
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    lazy = false,
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
          },
        },
      })
    end,
  },
}
