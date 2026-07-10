return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" }, -- lazy-load on buffer open
	opts = {
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
			markdown = { "prettier" },
			graphql = { "prettier" },
			vue = { "prettier" },
			svelte = { "prettier" },
			-- add more as needed
		},
		-- Prefer prettierd (daemon) for speed, fallback to prettier
		formatters = {
			prettier = {
				-- Try prettierd first (much faster), then plain prettier
				command = "prettierd", -- optional: explicitly prefer daemon
			},
		},
		-- Optional: format on save
		format_on_save = {
			timeout_ms = 500,
			lsp_fallback = true, -- fallback to LSP if no formatter found
		},
	},
}
