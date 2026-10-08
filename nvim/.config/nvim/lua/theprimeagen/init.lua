require("theprimeagen.set")
require("theprimeagen.remap")
require("theprimeagen.lazy_init")

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local ThePrimeagenGroup = augroup("ThePrimeagen", {})
local yank_group = augroup("HighlightYank", {})

-- Reload a lua module from disk (handy while editing the config itself).
function R(name)
  require("plenary.reload").reload_module(name)
end

vim.filetype.add({
  extension = {
    templ = "templ",
  },
})

autocmd("TextYankPost", {
  group = yank_group,
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({
      higroup = "IncSearch",
      timeout = 40,
    })
  end,
})

-- Strip trailing whitespace on save.
autocmd({ "BufWritePre" }, {
  group = ThePrimeagenGroup,
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

autocmd("LspAttach", {
  group = ThePrimeagenGroup,
  callback = function(e)
    local opts = { buffer = e.buf }
    vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
    vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
    vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
    vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
    vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
    vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
    vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
    vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
    vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
    vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
  end,
})

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

-- Neovim ships no Ansible filetype detection, so mark playbooks and role files
-- as `yaml.ansible` -- that is what ansiblels and ansible-lint attach to.
autocmd({ "BufNewFile", "BufRead" }, {
  group = augroup("user_ansible_ftdetect", { clear = true }),
  pattern = { "*.yml", "*.yaml" },
  callback = function(args)
    local buf = args.buf

    local function set_ansible()
      vim.bo[buf].filetype = "yaml.ansible"
    end

    local path = args.file and vim.fn.fnamemodify(args.file, ":p") or ""
    if
      path:match("/roles/[^/]+/(tasks|handlers|defaults|vars|meta)/")
      or path:match("/playbooks?/")
      or path:match("/group_vars/")
      or path:match("/host_vars/")
    then
      return set_ansible()
    end

    local ok, lines = pcall(vim.api.nvim_buf_get_lines, buf, 0, 40, false)
    if ok then
      local head = table.concat(lines, "\n")
      if head:match("^%s*%-%s*hosts:") or head:match("\n%s*%-%s*hosts:") then
        return set_ansible()
      end
    end
  end,
})
