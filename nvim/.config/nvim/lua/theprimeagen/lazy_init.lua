local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazy_entry = lazypath .. "/lua/lazy/init.lua"
-- Check the checkout, not just the directory: a clone interrupted mid-way leaves
-- an empty .git that makes every later start fail with "module 'lazy' not found".
if not (vim.uv or vim.loop).fs_stat(lazy_entry) then
  vim.fn.delete(lazypath, "rf")
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = "theprimeagen.lazy",
  change_detection = { notify = false },
  -- plenary ships a rockspec, so lazy would otherwise add a luarocks "build"
  -- step. It fails without system readline headers and the install loop never
  -- settles ("Too many rounds of missing plugins"), so rocks are turned off.
  rocks = { enabled = false },
})
