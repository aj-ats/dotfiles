return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	cmd = "Telescope",
	-- Keys defined in config/lazy.lua use require() so they also lazy-load.
	-- Listing them here keeps lazy.nvim aware of the bindings for :Lazy.
	keys = {
		{ "<leader>ff", desc = "Telescope find files" },
		{ "<leader>fg", desc = "Telescope live grep" },
		{ "<leader>fb", desc = "Telescope buffers" },
		{ "<leader>fh", desc = "Telescope help tags" },
		{ "<leader>fn", desc = "Find all files in a dir" },
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
