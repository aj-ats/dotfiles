-- nvim-treesitter (master branch — frozen but still the supported API for Nvim 0.10/0.11).
-- Do NOT lazy-load; do NOT call a second require("lazy").setup.
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "master",
	lazy = false,
	build = ":TSUpdate",
	-- Module that actually accepts ensure_installed / highlight opts
	main = "nvim-treesitter.configs",
	opts = {
		-- Core nvim + languages you actually use (py / js-ts-vue / sql / shell / etc.)
		ensure_installed = {
			"bash",
			"c",
			"css",
			"diff",
			"dockerfile",
			"git_config",
			"git_rebase",
			"gitcommit",
			"gitignore",
			"html",
			"javascript",
			"jsdoc",
			"json",
			"jsonc",
			"lua",
			"luadoc",
			"luap",
			"markdown",
			"markdown_inline",
			"python",
			"query",
			"regex",
			"sql",
			"toml",
			"tsx",
			"typescript",
			"vim",
			"vimdoc",
			"vue",
			"yaml",
		},
		sync_install = false,
		-- ensure_installed already covers your stack; auto_install on every
		-- unknown ft can stall open (network + compile) under WSL.
		auto_install = false,
		highlight = {
			enable = true,
			-- Skip treesitter on huge files (keeps nvim snappy on dumps / minified bundles)
			disable = function(_, buf)
				local max_filesize = 200 * 1024 -- 200 KB
				local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
				if ok and stats and stats.size > max_filesize then
					return true
				end
			end,
			additional_vim_regex_highlighting = false,
		},
		indent = {
			enable = true,
			-- vue / python indent via treesitter is still flaky for some people
			disable = { "python", "yaml" },
		},
		incremental_selection = {
			enable = true,
			keymaps = {
				init_selection = "<leader>ss",
				node_incremental = "<leader>si",
				scope_incremental = "<leader>sc",
				node_decremental = "<leader>sd",
			},
		},
	},
	config = function(_, opts)
		require("nvim-treesitter.configs").setup(opts)

		-- Treesitter-based folds (closed by default; use zc/zo/za)
		vim.opt.foldmethod = "expr"
		vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.opt.foldlevel = 99
		vim.opt.foldlevelstart = 99
		vim.opt.foldenable = true
	end,
}
