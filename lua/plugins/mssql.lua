return {
	"Kurren123/mssql.nvim",
	ft = { "sql" },
	init = function()
		-- SqlToolsService is built for .NET 8; this host has .NET 10.
		vim.env.DOTNET_ROLL_FORWARD = "LatestMajor"
	end,
	opts = {
		keymap_prefix = "<leader>m",
		sql_buffer_options = {
			expandtab = true,
			tabstop = 2,
			shiftwidth = 2,
			softtabstop = 2,
		},
		lsp_settings = {
			format = {
				placeSelectStatementReferencesOnNewLine = true,
				keywordCasing = "Uppercase",
				datatypeCasing = "Uppercase",
				alignColumnDefinitionsInColumns = true,
			},
		},
	},
}