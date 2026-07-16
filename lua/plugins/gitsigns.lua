return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		-- Thicker / ASCII-friendly glyphs so signs stay visible in WT/WSL fonts
		signs = {
			add = { text = "+" },
			change = { text = "~" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
			untracked = { text = "?" },
		},
		signs_staged = {
			add = { text = "+" },
			change = { text = "~" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
		},
		signs_staged_enable = true,
		-- "Enable gitsigns drawing" (not the vim option). Real column width is set in init.lua.
		signcolumn = true,
		numhl = false,
		linehl = false,
		word_diff = false,
		attach_to_untracked = true,
		-- Higher than default (6) so git hunks still win a slot when diagnostics compete.
		sign_priority = 10,
		current_line_blame = false, -- toggle with <leader>gb
		current_line_blame_opts = {
			delay = 400,
			virt_text_pos = "eol",
		},
		preview_config = {
			border = "rounded",
		},
		on_attach = function(bufnr)
			local gs = require("gitsigns")

			local function map(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
			end

			-- Navigation (skip if in diff mode so default [c / ]c still work)
			map("n", "]c", function()
				if vim.wo.diff then
					vim.cmd.normal({ "]c", bang = true })
				else
					gs.nav_hunk("next")
				end
			end, "Git: next hunk")

			map("n", "[c", function()
				if vim.wo.diff then
					vim.cmd.normal({ "[c", bang = true })
				else
					gs.nav_hunk("prev")
				end
			end, "Git: prev hunk")

			-- Actions (leader is <space>)
			map("n", "<leader>hs", gs.stage_hunk, "Git: stage hunk")
			map("n", "<leader>hr", gs.reset_hunk, "Git: reset hunk")
			map("v", "<leader>hs", function()
				gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Git: stage selection")
			map("v", "<leader>hr", function()
				gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Git: reset selection")
			map("n", "<leader>hS", gs.stage_buffer, "Git: stage buffer")
			map("n", "<leader>hR", gs.reset_buffer, "Git: reset buffer")
			map("n", "<leader>hu", gs.undo_stage_hunk, "Git: undo stage hunk")
			map("n", "<leader>hp", gs.preview_hunk, "Git: preview hunk")
			map("n", "<leader>hb", function()
				gs.blame_line({ full = true })
			end, "Git: blame line")
			map("n", "<leader>hd", gs.diffthis, "Git: diff this")
			map("n", "<leader>hD", function()
				gs.diffthis("~")
			end, "Git: diff against last commit")

			-- Toggles
			map("n", "<leader>gb", gs.toggle_current_line_blame, "Git: toggle line blame")
			map("n", "<leader>gt", gs.toggle_deleted, "Git: toggle deleted")

			-- Text object: ih = "in hunk"
			map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Git: select hunk")
		end,
	},
}
