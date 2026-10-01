-- DevOps / SRE toolchain for Neovim.
-- Editor integration only: LSP servers, linters, formatters and Treesitter
-- parsers are wired up per filetype. Everything installable through Mason is
-- installed automatically on startup.
--
-- Some tools need host prerequisites Mason can't provide here and are therefore
-- NOT auto-installed (see the notes at the bottom of this file):
--   * pip  -> yamllint, ansible-lint (ansible-lint is provided by the Ansible
--             venv installed alongside this config, so it is wired up)
--   * Go   -> regols, jq-lsp, jsonnet-language-server, hclfmt, dockerfmt
--   * Rust -> flux-lsp, shellharden
return {
  ---------------------------------------------------------------------------
  -- LazyVim language extras. Each one wires the LSP server, Treesitter
  -- parsers, formatters (conform) and linters (nvim-lint) for its language.
  -- (lang.ansible is NOT used because it insists on Mason-installing
  -- ansible-lint, which needs pip; Ansible is wired up by hand below.)
  ---------------------------------------------------------------------------
  { import = "lazyvim.plugins.extras.lang.yaml" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.docker" },
  { import = "lazyvim.plugins.extras.lang.helm" },
  { import = "lazyvim.plugins.extras.lang.terraform" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.markdown" },
  { import = "lazyvim.plugins.extras.lang.rego" },

  ---------------------------------------------------------------------------
  -- Extra LSP servers. Any server listed here is auto-installed by
  -- mason-lspconfig and enabled when a matching file is opened.
  ---------------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {}, -- Bash / shell scripts
        ansiblels = {}, -- Ansible playbooks / roles
        gh_actions_ls = {}, -- GitHub Actions workflow YAML
        -- Needs the Go toolchain, which is not installed on this machine.
        regols = { enabled = false },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Ansible: run playbooks/roles from the editor. ansible-lint is supplied by
  -- the Ansible venv in ~/.local/share/ansible-venv (see README notes).
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
  -- Treesitter parsers for the DevOps stack.
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "dockerfile",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "git_config",
        "go",
        "gomod",
        "gosum",
        "gotmpl",
        "gowork",
        "graphql",
        "hcl",
        "helm",
        "ini",
        "jq",
        "json5",
        "make",
        "nginx",
        "pem",
        "promql",
        "properties",
        "rego",
        "sql",
        "ssh_config",
        "terraform",
        "cue",
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- Command-line tools, linters and formatters installed through Mason.
  -- Only list tools NOT already installed by the language extras above (those
  -- pull in hadolint, tflint, markdownlint-cli2, ... themselves). Duplicating
  -- an entry makes Mason error with "Package is already installing".
  ---------------------------------------------------------------------------
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "yamlfmt", -- YAML
        "actionlint", -- GitHub Actions
        "shellcheck", -- shell
        "docker-compose-linter", -- Docker Compose
        "kube-linter", -- Kubernetes
        "kubescape", -- Kubernetes
        "trivy", -- IaC / container security
        "checkmake", -- Makefiles
        "dotenv-linter", -- .env
        "jq", -- data / query
        "yq", -- data / query
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Formatting (conform.nvim).
  ---------------------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        yaml = { "yamlfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Linting (nvim-lint).
  ---------------------------------------------------------------------------
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        yaml = { "actionlint" },
        -- Ansible linting comes from ansible-language-server (it runs
        -- ansible-lint itself); mapping ansible_lint here too would duplicate
        -- every diagnostic.
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
      },
      linters = {
        -- actionlint only understands GitHub Actions workflows, so keep it
        -- away from every other YAML file (k8s manifests, compose, ...).
        actionlint = {
          condition = function(ctx)
            return ctx.filename:find("%.github/workflows/") ~= nil
          end,
        },
      },
    },
  },
}
