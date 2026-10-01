-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Neovim ships no Ansible filetype detection, so mark playbooks and role files
-- as `yaml.ansible`. That is what ansiblels and ansible-lint attach to.
-- Registered here (not in config/autocmds.lua) so it also runs for a file
-- passed on the command line, before lazy.nvim finishes starting up.
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = vim.api.nvim_create_augroup("user_ansible_ftdetect", { clear = true }),
  pattern = { "*.yml", "*.yaml" },
  callback = function(args)
    local set_ansible = function()
      vim.bo[args.buf].filetype = "yaml.ansible"
    end

    -- Layout-based detection: role subtrees, playbooks and inventory vars.
    local path = args.file and vim.fn.fnamemodify(args.file, ":p") or ""
    if
      path:match("/roles/[^/]+/(tasks|handlers|defaults|vars|meta)/")
      or path:match("/playbooks?/")
      or path:match("/group_vars/")
      or path:match("/host_vars/")
    then
      return set_ansible()
    end

    -- Content-based detection: a playbook starts with a list of plays
    -- (`- hosts: ...` / `- name: ...`) and has a `tasks:`/`roles:` key.
    local ok, lines = pcall(vim.api.nvim_buf_get_lines, args.buf, 0, 40, false)
    if ok then
      local head = table.concat(lines, "\n")
      if head:match("^%s*%-%s*hosts:") or head:match("\n%s*%-%s*hosts:") then
        return set_ansible()
      end
    end
  end,
})
