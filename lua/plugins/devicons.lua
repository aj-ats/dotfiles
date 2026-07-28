-- File / filetype icons (Nerd Font glyphs).
-- Lazy-loaded via telescope / nvim-tree dependencies — not needed at bare startup.
--
-- REQUIRES a Nerd Font in your terminal (Windows Terminal font), e.g.:
--   JetBrainsMono Nerd Font, Cascadia Code NF, MesloLGS NF, Hack Nerd Font
-- Cheat sheet: https://www.nerdfonts.com/cheat-sheet
-- Preview all icons in nvim: :NvimWebDeviconsHiTest

return {
	"nvim-tree/nvim-web-devicons",
	lazy = true,
	config = function()
		require("nvim-web-devicons").setup({
			default = true,
			color_icons = true,
			override = {
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
			override_by_filename = {},
			override_by_extension = {},
		})
	end,
}
