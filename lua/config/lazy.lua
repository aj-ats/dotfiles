-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
     { import = "plugins" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})
--- i proabbly shoul de couple bellow this line into config.keymaps & config.wsl funcs etc...but fuck it 
-- fuck windows wsl I need to fix this on new laptop when I get time to set it up... but this keybind will delete the ^M that is pasted after I paste. I know this if from line 70-eof will fix on new machine I need to built features 
--this FW(fuck windows) command is to delete the last charchters on a every line of a selected visual block of code 
vim.api.nvim_set_keymap('n', 'FW', ':'<,'>normal $x')
-- WQ = :wq
vim.api.nvim_set_keymap('n', 'WQ', ':wq!<CR>', { noremap = true, silent = true })
-- WW = write no quit 
vim.api.nvim_set_keymap('n', 'WW', ':w!<CR>', { noremap = true, silent = true })
-- QQ = q!
vim.api.nvim_set_keymap('n', 'QQ', ':q!<CR>', { noremap = true, silent = true })
-- U = ctrl r (REDO)
vim.api.nvim_set_keymap('n', 'U', '<C-r>', { noremap = true, silent = true })
-- noremap U <Cmd>redo<CR>
-- Map <leader>y to write selected text to clipboard
--vim.api.nvim_set_keymap('w', '<leader>y', ":'<,'>w !clip.exe<CR>", { noremap = true, silent = true })
-- jq keymap you ned install jq but who does not
vim.api.nvim_set_keymap('v', 'jq', ':%!jq .<CR>', { noremap = true, silent = true })
-- string jq
vim.api.nvim_set_keymap('v', 'sjq', ':%!jq -c .<CR>', { noremap = true, silent = true })
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

-- Use Windows clipboard from WSL via clip.exe / PowerShell
if vim.fn.executable("clip.exe") == 1 then
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = {
      ["+"] = "clip.exe",
      ["*"] = "clip.exe",
    },
    paste = {
      ["+"] = "powershell.exe -NoProfile -Command \"Get-Clipboard | Out-String -Stream | ForEach-Object { $_ -replace '\\r', '' }\"",
      ["*"] = "powershell.exe -NoProfile -Command \"Get-Clipboard | Out-String -Stream | ForEach-Object { $_ -replace '\\r', '' }\"",
      ["+"] = "powershell.exe -NoProfile -Command Get-Clipboard",
      ["*"] = "powershell.exe -NoProfile -Command Get-Clipboard",
    },
    cache_enabled = 0,
  }
  -- Send all yanks/deletes to the system clipboard by default
  vim.opt.clipboard = "unnamedplus"
end

--[[ this is whats currenlty in my confifg.. uptop windows cliboard idk why i switched. both fucking dont work 
if vim.fn.executable("clip.exe") == 1 then
        -- Existing: Copy yanks to Windows clipboard
        vim.api.nvim_create_autocmd("TextYankPost", {
                group = vim.api.nvim_create_augroup("WslYank", { clear = true }),
                callback = function()
                        if vim.v.event.operator == "y" then
                                local text = vim.fn.getreg('"')
                                -- Convert LF → CRLF so Windows apps display lines correctly
                                local crlf_text = text:gsub("\n", "\r\n")
                                vim.fn.system("clip.exe", crlf_text)
                        end
                end,
        })

        vim.opt.clipboard = "unnamedplus"
end
]]


