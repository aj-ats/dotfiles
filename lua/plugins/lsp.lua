return {
	-- Lua-only helper; keep separate so it never loads with general LSP setup.
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		-- Defer until you actually open a file (biggest startup win after telescope).
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			-- Built-in completion menu behavior (nvim 0.11+)
			vim.opt.completeopt = { "menu", "menuone", "noselect", "popup" }

			-- Signs / underlines for errors (IntelliSense red squiggles)
			vim.diagnostic.config({
				virtual_text = { spacing = 2, prefix = "●" },
				signs = true,
				underline = true,
				update_in_insert = false,
				float = { border = "rounded", source = true },
			})

			-- Keymaps + completion when an LSP attaches to a buffer
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
				callback = function(args)
					local bufnr = args.buf
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if not client then
						return
					end

					local function map(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
					end

					map("n", "K", function()
						vim.lsp.buf.hover({ border = "rounded", max_width = 80, max_height = 20 })
					end, "LSP: hover docs")
					map("n", "<C-k>", function()
						vim.lsp.buf.hover({ border = "rounded", max_width = 80, max_height = 20 })
					end, "LSP: hover docs")

					map("i", "<C-s>", function()
						vim.lsp.buf.signature_help({ border = "rounded" })
					end, "LSP: signature help")
					map("n", "gs", function()
						vim.lsp.buf.signature_help({ border = "rounded" })
					end, "LSP: signature help")

					map("n", "gd", vim.lsp.buf.definition, "LSP: go to definition")
					map("n", "gD", vim.lsp.buf.declaration, "LSP: go to declaration")
					map("n", "gi", vim.lsp.buf.implementation, "LSP: implementations")
					map("n", "gr", vim.lsp.buf.references, "LSP: references")
					map("n", "gy", vim.lsp.buf.type_definition, "LSP: type definition")

					map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: rename")
					map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "LSP: code action")

					map("n", "[d", function()
						vim.diagnostic.jump({ count = -1, float = true })
					end, "Prev diagnostic")
					map("n", "]d", function()
						vim.diagnostic.jump({ count = 1, float = true })
					end, "Next diagnostic")
					map("n", "<leader>d", vim.diagnostic.open_float, "Line diagnostics")

					if client:supports_method("textDocument/completion") then
						vim.lsp.completion.enable(true, client.id, bufnr, {
							autotrigger = true,
						})
					end
				end,
			})

			-- Language servers (on PATH). Enable only here — not in lazy.lua / init.lua.
			-- Python: basedpyright only (do not also enable pyright).
			-- JS/TS/Vue: ts_ls. Lua: lua_ls. Docker: dockerls.
			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						-- Do NOT set workspace.library = nvim_get_runtime_file(...) —
						-- that walks the entire runtime on every lua buffer and is very slow.
						-- lazydev.nvim supplies the vim API library when editing lua.
						workspace = { checkThirdParty = false },
						diagnostics = { globals = { "vim" } },
						telemetry = { enable = false },
					},
				},
			})
			vim.lsp.config("ts_ls", {
				init_options = {
					plugins = {
						{
							name = "@vue/typescript-plugin",
							location = "/usr/local/lib/node_modules/@vue/typescript-plugin",
							languages = { "javascript", "typescript", "vue" },
						},
					},
				},
				filetypes = {
					"javascript",
					"typescript",
					"vue",
				},
			})
			vim.lsp.config("sqlls", {
				cmd = { "sql-language-server", "up", "--method", "stdio" },
				filetypes = { "sql", "mysql", "tsql" },
				root_markers = { ".sqllsrc.json" },
			})

			vim.filetype.add({
				extension = {
					tsql = "tsql",
				},
			})

			-- Only enable servers whose binary is actually on PATH.
			-- Broken/missing binaries still get spawned, crash, and stick open/quit.
			local function has_bin(name)
				return vim.fn.executable(name) == 1
			end

			-- basedpyright-langserver can exist as a broken stub (ModuleNotFoundError).
			-- Cheap FS check only — never spawn python (cold start is slow on WSL).
			local function basedpyright_ok()
				if not has_bin("basedpyright-langserver") and not has_bin("basedpyright") then
					return false
				end
				local bin = vim.fn.exepath("basedpyright-langserver")
				if bin == "" then
					bin = vim.fn.exepath("basedpyright")
				end
				if bin == "" then
					return false
				end
				-- user install: ~/.local/lib/pythonX.Y/site-packages/basedpyright
				local root = vim.fn.fnamemodify(bin, ":h:h")
				local matches = vim.fn.glob(root .. "/lib/python*/site-packages/basedpyright/__init__.py", true, true)
				if type(matches) == "table" and #matches > 0 then
					return true
				end
				-- pipx default path
				local pipx = vim.fn.expand("~/.local/share/pipx/venvs/basedpyright/lib/python*/site-packages/basedpyright/__init__.py")
				matches = vim.fn.glob(pipx, true, true)
				return type(matches) == "table" and #matches > 0
			end

			local enable = {}
			if has_bin("lua-language-server") then
				enable[#enable + 1] = "lua_ls"
			end
			if basedpyright_ok() then
				enable[#enable + 1] = "basedpyright"
			end
			-- Intentionally skip a noisy notify on every open when the stub is broken;
			-- reinstall with: pipx install basedpyright  (or pip install --user basedpyright)
			if has_bin("typescript-language-server") then
				enable[#enable + 1] = "ts_ls"
			end
			if has_bin("sql-language-server") then
				enable[#enable + 1] = "sqlls"
			end
			if has_bin("docker-langserver") then
				enable[#enable + 1] = "dockerls"
			end
			if #enable > 0 then
				vim.lsp.enable(enable)
			end
		end,
	},
}
