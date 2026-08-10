-- Use master, not tag 0.1.8 / 0.1.x.
-- 0.1.x still calls nvim-treesitter.parsers.ft_to_lang (removed on treesitter main),
-- which breaks previews on Neovim 0.12+ — see telescope#3487.
return {
	"nvim-telescope/telescope.nvim",
	branch = "master",
	cmd = "Telescope",
	-- rhs required: desc-only keys get deleted by lazy after first load and never restored.
	keys = {
		{
			"<leader>ff",
			function()
				require("telescope.builtin").find_files()
			end,
			desc = "Telescope find files",
		},
		{
			"<leader>fg",
			function()
				require("telescope.builtin").live_grep()
			end,
			desc = "Telescope live grep",
		},
		{
			"<leader>fb",
			function()
				require("telescope.builtin").buffers()
			end,
			desc = "Telescope buffers",
		},
		{
			"<leader>fh",
			function()
				require("telescope.builtin").help_tags()
			end,
			desc = "Telescope help tags",
		},
		{
			"<leader>fn",
			function()
				require("telescope.builtin").find_files({
					no_ignore = true,
					hidden = true,
				})
			end,
			desc = "Find all files in a dir",
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("telescope").setup({
			defaults = {
				layout_config = {
					horizontal = { preview_width = 0.5 },
				},
				path_display = { "smart" },
			},
		})
	end,
}
