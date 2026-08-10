-- nvim-treesitter `main` is required for Neovim 0.12+.
-- `master` / v0.10.x are frozen and cause highlighter "range" nil errors on 0.12.
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		local ts = require("nvim-treesitter")

		ts.setup({
			install_dir = vim.fn.stdpath("data") .. "/site",
		})

		local langs = {
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
		}

		-- Async install (no-op if already present). Re-run :TSUpdate after upgrades.
		ts.install(langs)

		local max_filesize = 200 * 1024 -- 200 KB

		local no_indent = {
			python = true,
			yaml = true,
		}

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
			callback = function(ev)
				local buf = ev.buf
				local ft = ev.match

				local ok_stat, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
				if ok_stat and stats and stats.size > max_filesize then
					return
				end

				-- Highlight / injections (Neovim built-in)
				pcall(vim.treesitter.start, buf)

				-- Folds
				vim.wo.foldmethod = "expr"
				vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.wo.foldlevel = 99
				vim.opt.foldlevelstart = 99
				vim.opt.foldenable = true

				-- Indent (plugin; experimental — skip flaky fts)
				if not no_indent[ft] then
					vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
