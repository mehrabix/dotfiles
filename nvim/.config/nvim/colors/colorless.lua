-- Entry point for `:colorscheme colorless`.
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
require("theprimeagen.colors.colorless").load()
