-- File / filetype icons (Nerd Font glyphs).
-- Used by nvim-tree, and anything you call require("nvim-web-devicons") from.
--
-- REQUIRES a Nerd Font in your terminal (Windows Terminal font), e.g.:
--   JetBrainsMono Nerd Font, Cascadia Code NF, MesloLGS NF, Hack Nerd Font
-- Cheat sheet: https://www.nerdfonts.com/cheat-sheet
-- Preview all icons in nvim: :NvimWebDeviconsHiTest

return {
	"nvim-tree/nvim-web-devicons",
	lazy = false, -- load early so tree / telescope can use icons on first open
	priority = 900,
	config = function()
		require("nvim-web-devicons").setup({
			-- Fall back to a default glyph when no match is found
			default = true,
			-- true = strict color; false = blend with colorscheme a bit
			color_icons = true,
			-- "dark" | "light" | nil (auto from vim.o.background)
			-- variant = "dark",

			-- Override / add icons by extension or exact filename
			-- icon  = Nerd Font codepoint (string glyph)
			-- color = #rrggbb used for highlight
			-- name  = highlight group suffix (DevIcon{name})
			override = {
				-- by extension
				lua = {
					icon = "",
					color = "#51a0cf",
					cterm_color = "74",
					name = "Lua",
				},
				py = {
					icon = "",
					color = "#ffbc03",
					cterm_color = "214",
					name = "Py",
				},
				ts = {
					icon = "",
					color = "#519aba",
					cterm_color = "74",
					name = "Ts",
				},
				js = {
					icon = "",
					color = "#f1e05a",
					cterm_color = "185",
					name = "Js",
				},
				json = {
					icon = "",
					color = "#cbcb41",
					cterm_color = "185",
					name = "Json",
				},
				md = {
					icon = "",
					color = "#519aba",
					cterm_color = "74",
					name = "Md",
				},
				-- by exact filename
				[".gitignore"] = {
					icon = "",
					color = "#f1502f",
					cterm_color = "196",
					name = "GitIgnore",
				},
				Makefile = {
					icon = "",
					color = "#6d8086",
					cterm_color = "66",
					name = "Makefile",
				},
			},

			-- Icon used when default = true and nothing matches
			override_by_filename = {
				-- [".env"] = { icon = "", color = "#faf743", name = "Env" },
			},
			override_by_extension = {
				-- ["log"] = { icon = "", color = "#81e043", name = "Log" },
			},
		})
	end,
}
