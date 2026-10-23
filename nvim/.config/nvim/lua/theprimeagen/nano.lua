-- Nano-friendly keys layered on top of the normal Vim bindings.
-- Ctrl+S / Ctrl+Q only reach Neovim when the shell disables terminal flow
-- control: `stty -ixon` (already added to .zshrc).
local map = vim.keymap.set

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

local function save_buffer()
  if not vim.bo.modifiable then
    return
  end

  if vim.api.nvim_buf_get_name(0) == "" then
    vim.ui.input({ prompt = "Save as: ", completion = "file" }, function(path)
      if not path or path == "" then
        return
      end
      local ok, err = pcall(vim.cmd, "write " .. vim.fn.fnameescape(path))
      if not ok then
        notify(err, vim.log.levels.ERROR)
      end
    end)
    return
  end

  local ok, err = pcall(vim.cmd.write)
  if not ok then
    notify(err, vim.log.levels.ERROR)
  end
end

local function quit()
  local modified = false
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
      modified = true
      break
    end
  end

  if not modified then
    vim.cmd("quitall")
    return
  end

  local choice = vim.fn.confirm("Save changes before quitting?", "&Save  &Discard  &Cancel", 1)
  if choice == 1 then
    vim.cmd("wall")
    vim.cmd("quitall")
  elseif choice == 2 then
    vim.cmd("quitall!")
  end
end

local function find_files()
  local ok, builtin = pcall(require, "telescope.builtin")
  if ok then
    builtin.find_files()
  else
    vim.cmd("edit")
  end
end

-- Save (normal, insert and visual mode, like a GUI editor).
map({ "n", "i", "v" }, "<C-s>", save_buffer, { desc = "Save file" })

-- Quit, prompting to save modified buffers.
map("n", "<C-q>", quit, { desc = "Quit Neovim" })

-- Open / find a file.
map("n", "<C-o>", find_files, { desc = "Open file" })
map("n", "<C-f>", find_files, { desc = "Find file" })

-- Cut line (nano Ctrl+K) and paste it back (nano Ctrl+U).
map({ "n", "v" }, "<C-k>", "dd", { desc = "Cut line" })
map({ "n", "v" }, "<C-u>", "p", { desc = "Paste" })

-- Contextual help.
map({ "n", "v" }, "<F1>", "<Cmd>help<CR>", { desc = "Help" })


