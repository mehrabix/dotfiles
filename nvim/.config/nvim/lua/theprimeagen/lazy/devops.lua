-- DevOps / SRE toolchain layered on top of the Primeagen base config.
-- LSP servers live in lazy/lsp.lua; this file only adds the extra editors
-- tools (Mason CLI installs, Ansible runner, Java) that do not come from an
-- LSP server.
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
        "hadolint", -- Dockerfile
        "tflint", -- Terraform
        "markdownlint-cli2", -- Markdown
        "checkmake", -- Makefiles
        "dotenv-linter", -- .env
        "ruff", -- Python
        "regal", -- Rego
        "jq", -- data / query
        "yq", -- data / query
        "docker-compose-linter", -- Docker Compose
        "kube-linter", -- Kubernetes
        "kubescape", -- Kubernetes
        "trivy", -- IaC / container security
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Ansible: run playbooks/roles from the editor.
  ---------------------------------------------------------------------------
  {
    "mfussenegger/nvim-ansible",
    ft = { "yaml", "yaml.ansible" },
    keys = {
      {
        "<leader>ta",
        function()
          require("ansible").run()
        end,
        ft = "yaml.ansible",
        desc = "Ansible Run Playbook/Role",
        silent = true,
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
