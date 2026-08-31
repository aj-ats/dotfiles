local function prettier_tsql_plugin()
	local node = vim.fn.exepath("node")
	if node == "" then
		return nil
	end
	local path = vim.fs.joinpath(
		vim.fn.fnamemodify(node, ":h:h"),
		"lib",
		"node_modules",
		"prettier-plugin-tsql",
		"dist",
		"index.js"
	)
	if vim.uv.fs_stat(path) then
		return path
	end
	return nil
end

return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" }, -- lazy-load on buffer open
	opts = function()
		local tsql_plugin = prettier_tsql_plugin()

		return {
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				markdown = { "prettier" },
				typescriptreact = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				graphql = { "prettier" },
				vue = { "prettier" },
				svelte = { "prettier" },
				sql = { "prettier_tsql" },
				tsql = { "prettier_tsql" },
			},
			formatters = {
				prettier = {
					-- Try prettierd first (much faster), then plain prettier
					command = "prettierd", -- optional: explicitly prefer daemon
				},
				-- ScriptDOM T-SQL via prettier-plugin-tsql (not prettierd: needs .NET host)
				prettier_tsql = {
					command = "prettier",
					stdin = true,
					env = { DOTNET_ROLL_FORWARD = "LatestMajor" },
					condition = function()
						return tsql_plugin ~= nil and vim.fn.executable("prettier") == 1
					end,
					args = {
						"--stdin-filepath",
						"$FILENAME",
						"--plugin",
						tsql_plugin or "prettier-plugin-tsql",
						"--parser",
						"tsql",
						"--sql-keyword-case",
						"upper",
						"--sql-density",
						"standard",
						"--sql-comma-style",
						"trailing",
					},
				},
			},
			format_on_save = function(bufnr)
				local ft = vim.bo[bufnr].filetype
				-- First T-SQL format loads the .NET host (~2s); keep LSP out of SQL writes.
				if ft == "sql" or ft == "tsql" then
					return { timeout_ms = 5000, lsp_format = "never" }
				end
				return { timeout_ms = 500, lsp_format = "fallback" }
			end,
		}
	end,
}
