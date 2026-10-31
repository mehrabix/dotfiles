-- JetBrains-style UI layer: project tree, tabs, statusline, command hints,
-- notifications, git gutter, debug panel and an integrated terminal.
-- Keymaps live next to each plugin so they only exist once the plugin loads.
local palette = require("theprimeagen.palette")

return {
  ---------------------------------------------------------------------------
  -- Icons (required by the tree, tabs and statusline)
  ---------------------------------------------------------------------------
  { "nvim-tree/nvim-web-devicons", lazy = true },

  ---------------------------------------------------------------------------
  -- Project tool window (left sidebar)
  ---------------------------------------------------------------------------
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
      {
        "<A-p>",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
        end,
        desc = "Project tree",
      },
    },
    opts = {
      close_if_last_window = true,
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "open_current",
        use_libuv_file_watcher = true,
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      default_component_configs = {
        indent = { with_expanders = true },
      },
      window = {
        width = 32,
        mappings = {
          ["<space>"] = "none",
          ["<A-p>"] = "close_window",
        },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Editor tabs (top)
  ---------------------------------------------------------------------------
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    event = "VeryLazy",
    opts = {
      options = {
        mode = "buffers",
        diagnostics = "nvim_lsp",
        show_buffer_close_icons = true,
        show_close_icon = true,
        always_show_bufferline = true,
        separator_style = "slant",
        offsets = {
          {
            filetype = "neo-tree",
            text = "Project",
            text_align = "left",
            separator = true,
          },
        },
      },
    },
    config = function(_, opts)
      require("bufferline").setup(opts)
      vim.keymap.set("n", "<Tab>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next tab" })
      vim.keymap.set("n", "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Previous tab" })
      vim.keymap.set("n", "<leader>bd", "<Cmd>bdelete<CR>", { desc = "Close tab" })
      vim.keymap.set("n", "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", { desc = "Close other tabs" })
    end,
  },

  ---------------------------------------------------------------------------
  -- Status bar / breadcrumbs (bottom)
  ---------------------------------------------------------------------------
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "SmiteshP/nvim-navic" },
    event = "VeryLazy",
    opts = {
      options = {
        theme = require("theprimeagen.lualine_theme"),
        globalstatus = true,
        section_separators = "",
        component_separators = "|",
        disabled_filetypes = { statusline = { "neo-tree" } },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = {
          { "filename", path = 1 },
          {
            function()
              local ok, navic = pcall(require, "nvim-navic")
              return ok and navic.get_location() or ""
            end,
            cond = function()
              local ok, navic = pcall(require, "nvim-navic")
              return ok and navic.is_available()
            end,
            color = { fg = palette.accent },
          },
        },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Breadcrumb provider used by lualine
  ---------------------------------------------------------------------------
  {
    "SmiteshP/nvim-navic",
    event = "LspAttach",
    opts = {
      lsp = {
        auto_attach = false,
      },
      separator = "  >  ",
      highlight = true,
    },
    config = function(_, opts)
      local navic = require("nvim-navic")
      navic.setup(opts)

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("ThePrimeagenNavic", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          if vim.api.nvim_buf_get_option(bufnr, "buftype") ~= "" then
            return
          end

          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then
            return
          end

          if not client.server_capabilities.documentSymbolProvider then
            return
          end

          -- Prefer jdtls for Java breadcrumbs; only fall back to spring-boot if
          -- nothing else is attached (avoids the navic "already attached" warning).
          if client.name == "jdtls" then
            if vim.b[bufnr].navic_client_name and vim.b[bufnr].navic_client_name ~= "jdtls" then
              -- Replace spring-boot/navic attachment with jdtls if it becomes available
              pcall(navic.detach, bufnr)
            end
            navic.attach(client, bufnr)
            return
          end

          if client.name == "spring-boot" then
            if vim.b[bufnr].navic_client_name then
              return
            end
            navic.attach(client, bufnr)
          end
        end,
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- Which-key: shows available keys, like JetBrains' action hints
  ---------------------------------------------------------------------------
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = 300,
      icons = { rules = false },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer keymaps",
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Notifications + nicer command line
  ---------------------------------------------------------------------------
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    opts = {
      timeout = 3000,
      max_height = 10,
      stages = "fade",
    },
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
      routes = {
        { filter = { event = "msg_show", find = "written" }, opts = { skip = true } },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Git gutter + hunk actions
  ---------------------------------------------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)
      local gs = require("gitsigns")
      vim.keymap.set("n", "]c", function() gs.nav_hunk("next") end, { desc = "Next change" })
      vim.keymap.set("n", "[c", function() gs.nav_hunk("prev") end, { desc = "Previous change" })
      vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { desc = "Preview hunk" })
      vim.keymap.set("n", "<leader>gs", gs.stage_hunk, { desc = "Stage hunk" })
      vim.keymap.set("n", "<leader>gr", gs.reset_hunk, { desc = "Reset hunk" })
      vim.keymap.set("n", "<leader>gb", gs.toggle_current_line_blame, { desc = "Blame line" })
    end,
  },

  ---------------------------------------------------------------------------
  -- Commenting and auto-pairs
  ---------------------------------------------------------------------------
  { "numToStr/Comment.nvim", event = "VeryLazy", opts = {} },
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

  ---------------------------------------------------------------------------
  -- Indent guides (JetBrains-style vertical lines)
  ---------------------------------------------------------------------------
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = { char = "│" },
      scope = { enabled = true, show_start = false, show_end = false },
    },
  },

  ---------------------------------------------------------------------------
  -- Integrated terminal (bottom tool window)
  ---------------------------------------------------------------------------
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      { "<A-t>", "<Cmd>ToggleTerm<CR>", desc = "Terminal" },
    },
    opts = {
      size = 15,
      direction = "horizontal",
      start_in_insert = true,
      shade_terminals = true,
    },
  },

  ---------------------------------------------------------------------------
  -- Debugger UI (problems/variables/stack/watches) + JetBrains debug keys
  ---------------------------------------------------------------------------
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    keys = {
      { "<A-d>", function() require("dapui").toggle() end, desc = "Debug panel" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup({})

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: start/continue" })
      vim.keymap.set("n", "<F9>", dap.continue, { desc = "Debug: continue" })
      vim.keymap.set("n", "<F7>", dap.step_into, { desc = "Debug: step into" })
      vim.keymap.set("n", "<F8>", dap.step_over, { desc = "Debug: step over" })
      vim.keymap.set("n", "<S-F8>", dap.step_out, { desc = "Debug: step out" })
      vim.keymap.set("n", "<C-F8>", dap.toggle_breakpoint, { desc = "Debug: toggle breakpoint" })
      vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Debug: terminate" })
    end,
  },
}
