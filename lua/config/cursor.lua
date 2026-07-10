-- Cursor: full block (incl. insert). Mode colors via OSC 12.
-- Under tmux+WSL, must write to /dev/tty AND wrap OSC in tmux DCS passthrough.

local M = {}

local cursor_colors = {
	n = "#7aa2f7", -- blue (normal)
	i = "#b9f27c", -- light green (insert)
	v = "#bb9af7", -- magenta (visual)
	V = "#bb9af7",
	["\22"] = "#bb9af7", -- CTRL-V block
	R = "#f7768e", -- red (replace)
	c = "#e0af68", -- yellow (cmdline)
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

function M.setup()
	-- full block in normal/visual/insert; underline in replace
	vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:block,r-cr-o:hor20"

	vim.api.nvim_create_autocmd({ "ModeChanged", "VimEnter", "VimResume", "TermEnter", "TermLeave" }, {
		group = vim.api.nvim_create_augroup("TokyonightCursor", { clear = true }),
		callback = function()
			vim.schedule(update_cursor_color)
		end,
	})

	vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
		group = vim.api.nvim_create_augroup("TokyonightCursorReset", { clear = true }),
		callback = reset_cursor_color,
	})
end

return M
