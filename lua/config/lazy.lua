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
		{ import = "plugins" },
	},
	install = { colorscheme = { "tokyonight", "habamax" } },
	-- Update checks in the background, infrequently (daily). Don't block UI.
	checker = {
		enabled = true,
		notify = false,
		frequency = 86400,
	},
	change_detection = {
		enabled = true,
		notify = false,
	},
	performance = {
		rtp = {
			-- Skip rarely-used built-in plugins (saves startup + :q work)
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})

vim.opt.mouse = ""

-- Reload file if changed on disk (e.g. git checkout). BufEnter alone is enough;
-- FocusGained fires a lot under WSL/tmux and re-stats the file every time.
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*",
	command = "checktime",
})

-- Cursor: full block (incl. insert). Mode colors live in config.cursor.
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:block,r-cr-o:hor20"

-- FW: delete last char on every line of a visual selection (e.g. strip ^M from Windows paste).
vim.api.nvim_set_keymap("x", "FW", [[:<C-u>'<,'>normal! $x<CR>]], { noremap = true, silent = true })
-- WQ = :wq
vim.api.nvim_set_keymap("n", "WQ", ":wq!<CR>", { noremap = true, silent = true })
-- WW = write no quit
vim.api.nvim_set_keymap("n", "WW", ":w!<CR>", { noremap = true, silent = true })
-- QQ = q! (stop LSPs first so quit doesn't wait on dying language servers)
vim.keymap.set("n", "QQ", function()
	pcall(vim.lsp.stop_client, vim.lsp.get_clients(), true)
	vim.cmd("q!")
end, { noremap = true, silent = true, desc = "Force quit (stop LSPs first)" })
-- U = redo
vim.api.nvim_set_keymap("n", "U", "<C-r>", { noremap = true, silent = true })

-- jq keymaps (requires jq on PATH)
vim.api.nvim_set_keymap("v", "jq", ":%!jq .<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "sjq", ":%!jq -c .<CR>", { noremap = true, silent = true })

-- lc: visual selection stats as lines:chars (e.g. 7:55)
vim.keymap.set("x", "lc", function()
	local s = vim.fn.getpos("v")
	local e = vim.fn.getpos(".")
	local mode = vim.fn.mode()
	local region = vim.fn.getregion(s, e, { type = mode })
	local lines = #region
	local chars = 0
	for i, line in ipairs(region) do
		chars = chars + vim.fn.strchars(line)
		if i < lines then
			chars = chars + 1
		end
	end
	vim.notify(string.format("%d:%d", lines, chars), vim.log.levels.INFO)
end, { desc = "Selection line:char count", silent = true })

-- Telescope: lazy-loaded via keys — do NOT require('telescope.builtin') at startup.
vim.keymap.set("n", "<leader>ff", function()
	require("telescope.builtin").find_files()
end, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", function()
	require("telescope.builtin").live_grep()
end, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", function()
	require("telescope.builtin").buffers()
end, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", function()
	require("telescope.builtin").help_tags()
end, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>fn", function()
	require("telescope.builtin").find_files({
		no_ignore = true,
		hidden = true,
	})
end, { desc = "Find all files in a dir" })

-- On quit: force-stop language servers so :q! / QQ don't hang waiting for them.
vim.api.nvim_create_autocmd("VimLeavePre", {
	group = vim.api.nvim_create_augroup("FastQuit", { clear = true }),
	callback = function()
		for _, client in ipairs(vim.lsp.get_clients()) do
			pcall(client.stop, client, true)
		end
	end,
})

-- WSL → Windows clipboard: yank only (async). Avoid clipboard=unnamedplus —
-- that makes every delete/yank/put talk to Windows and slows open/quit hard.
if vim.fn.executable("clip.exe") == 1 then
	vim.api.nvim_create_autocmd("TextYankPost", {
		group = vim.api.nvim_create_augroup("WslYank", { clear = true }),
		callback = function()
			if vim.v.event.operator ~= "y" then
				return
			end
			local text = vim.fn.getreg('"'):gsub("\n", "\r\n")
			-- Non-blocking: clip.exe over /mnt/c is ~250–400ms if synchronous.
			vim.system({ "clip.exe" }, { stdin = text, detach = true })
		end,
	})
end
