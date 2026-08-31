-- Begin init.lua
-- leader
-- Absolute line numbers live in their own column, to the right of the sign gutter.
-- Signs are NOT line numbers: gitsigns uses "?" for untracked lines; LSP uses E/W/H.
vim.opt.number = true
--tabs
vim.opt.tabstop = 8
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
-- Room for gitsigns + LSP diagnostic signs (default "auto" is width 1 → git hunks get buried)
vim.opt.signcolumn = "yes:2"
--
require("config.lazy")
require("config.cursor").setup()
-- yank to windows clipboard from wsl
--xnoremap y y:!clip.exe<CR>
-- mouse mode off
