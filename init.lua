-- Begin init.lua
-- leader 
--tabs
vim.opt.tabstop = 8
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
--
require("config.lazy")
-- mouse mode off
vim.opt.mouse = ""
-- change file on git checkout 
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  pattern = "*",
  command = "checktime"
})

-- -----------tabs n shit
-- WQ = :wq
vim.api.nvim_set_keymap('n', 'WQ', ':wq<CR>', { noremap = true, silent = true })
-- WW = write no quit 
vim.api.nvim_set_keymap('n', 'WW', ':w<CR>', { noremap = true, silent = true })
-- QQ = q!
vim.api.nvim_set_keymap('n', 'QQ', ':q!<CR>', { noremap = true, silent = true })
-- Telescope conf 
local builtin = require('telescope.builtin')                                        
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })      
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
-- pyright 
vim.lsp.enable('basedpyright')
-- tree sitter 
require("lazy").setup({
  {"nvim-treesitter/nvim-treesitter", branch = 'master', lazy = false, build = ":TSUpdate"}
})
