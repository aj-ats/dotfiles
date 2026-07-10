return {
	{
		"folke/tokyonight.nvim",
		lazy = false,       -- Load during startup
		priority = 1000,    -- Ensure it loads before other plugins
		opts = {
			style = "night",  -- Options: "storm", "moon", "night", "day"
			transparent = false, -- Enable/disable background transparency
		},
		config = function(_, opts)
			require("tokyonight").setup(opts)
			vim.cmd([[colorscheme tokyonight]])
		end,
	},
}
--return {
--	'maxmx03/solarized.nvim',
--
--
--
--
--
--j`--	lazy = false,
--	priority = 1000,
--	---@type solarized.config
--	opts = {},
--	config = function(_, opts)
--		vim.o.termguicolors = true
--		vim.o.background = 'light'
--		require('solarized').setup(opts)
--		vim.cmd.colorscheme 'solarized'
--	end,
--}
