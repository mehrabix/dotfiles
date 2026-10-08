return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      yaml = { "actionlint" },
      -- ansible-lint runs inside ansible-language-server, so it is not mapped
      -- here (it would duplicate every diagnostic).
      dockerfile = { "hadolint" },
      terraform = { "tflint" },
      tf = { "tflint" },
      hcl = { "tflint" },
      sh = { "shellcheck" },
      bash = { "shellcheck" },
      zsh = { "shellcheck" },
      make = { "checkmake" },
      markdown = { "markdownlint-cli2" },
      python = { "ruff" },
      rego = { "regal" },
    }

    -- actionlint only understands GitHub Actions workflows; keep it away from
    -- every other YAML file (k8s manifests, compose, ...).
    lint.linters.actionlint = lint.linters.actionlint or {}
    local actionlint = lint.linters.actionlint
    actionlint.condition = function(ctx)
      return ctx.filename:find("%.github/workflows/") ~= nil
    end

    vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
      group = vim.api.nvim_create_augroup("user_lint", { clear = true }),
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
