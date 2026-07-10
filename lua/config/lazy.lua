-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out,                            "WarningMsg" },
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
vim.opt.mouse = ""
-- change file on git checkout
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
	pattern = "*",
	command = "checktime"
})
-- fuck windows wsl I need to fix this on new laptop when I get time to set it up... but this keybind will delete the ^M that is pasted after I paste. I know this if from line 70-eof will fix on new machine I need to built features
--
-- Cursor: full block (incl. insert). Mode colors via OSC 12.
-- Under tmux+WSL, must write to /dev/tty AND wrap OSC in tmux DCS passthrough.
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:block,r-cr-o:hor20"

local cursor_colors = {
	n = "#7aa2f7",      -- blue (normal)
	i = "#b9f27c",      -- light green (insert)
	v = "#bb9af7",      -- magenta (visual)
	V = "#bb9af7",
	["\22"] = "#bb9af7", -- CTRL-V block
	R = "#f7768e",      -- red (replace)
	c = "#e0af68",      -- yellow (cmdline)
	t = "#7aa2f7",
}

local function term_write(seq)
	local tty = io.open("/dev/tty", "w")
	if tty then
		tty:write(seq)
		tty:flush()
		tty:close()
	else
		io.write(seq)
		io.flush()
	end
end

local function set_cursor_color(hex)
	-- OSC 12 = set cursor color. Must pass through tmux or it never hits Windows Terminal.
	if vim.env.TMUX and vim.env.TMUX ~= "" then
		term_write("\27Ptmux;\27\27]12;" .. hex .. "\7\27\\")
	else
		term_write("\27]12;" .. hex .. "\7")
	end
end

local function reset_cursor_color()
	if vim.env.TMUX and vim.env.TMUX ~= "" then
		term_write("\27Ptmux;\27\27]112\7\27\\")
	else
		term_write("\27]112\7")
	end
end

local function update_cursor_color()
	local mode = vim.api.nvim_get_mode().mode
	local hex = cursor_colors[mode] or cursor_colors[mode:sub(1, 1)] or cursor_colors.n
	set_cursor_color(hex)
end

vim.api.nvim_create_autocmd({ "ModeChanged", "VimEnter", "VimResume", "TermEnter", "TermLeave" }, {
	callback = function()
		vim.schedule(update_cursor_color)
	end,
})
vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
	callback = reset_cursor_color,
})
-- FW: delete last char on every line of a visual selection (e.g. strip ^M from Windows paste).
-- <C-u> clears the auto-inserted '<,'> so we can set the range once ourselves.
vim.api.nvim_set_keymap('x', 'FW', [[:<C-u>'<,'>normal! $x<CR>]], { noremap = true, silent = true })
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
vim.keymap.set('n', '<leader>fn', function()
	builtin.find_files({
		no_ignore = true,
		hidden = true,
	})
end, { desc = 'Find all files in a dir' })
--vim.keymap.set('n', '<leader>fn', builtin.lsp_workspace_symbols {}
-- pyright

vim.lsp.enable('basedpyright')

-- tree sitter
require("lazy").setup({
	{ "nvim-treesitter/nvim-treesitter", branch = 'master', lazy = false, build = ":TSUpdate" }
})

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
