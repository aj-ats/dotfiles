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

			-- Diagnostics display modes (cycle with <leader>dt):
			--   quiet  — nothing on screen (use [d/]d and <leader>d to inspect)
			--   signs  — gutter icons + underline only (default; code stays readable)
			--   full   — signs + underline + end-of-line virtual text
			local diag_modes = {
				quiet = {
					virtual_text = false,
					signs = false,
					underline = false,
				},
				signs = {
					virtual_text = false,
					signs = true,
					underline = true,
				},
				full = {
					virtual_text = { spacing = 2, prefix = "●" },
					signs = true,
					underline = true,
				},
			}
			local diag_order = { "quiet", "signs", "full" }
			local diag_mode = "signs" -- default: readable

			local function apply_diag_mode(mode)
				diag_mode = mode
				local cfg = vim.tbl_extend("force", {
					update_in_insert = false,
					severity_sort = true,
					float = { border = "rounded", source = true, header = "", prefix = "" },
				}, diag_modes[mode])
				vim.diagnostic.config(cfg)
			end
			apply_diag_mode(diag_mode)

			local function cycle_diag_mode()
				local idx = 1
				for i, name in ipairs(diag_order) do
					if name == diag_mode then
						idx = i
						break
					end
				end
				local next_mode = diag_order[(idx % #diag_order) + 1]
				apply_diag_mode(next_mode)
				vim.notify("Diagnostics: " .. next_mode, vim.log.levels.INFO)
			end

			-- Global (always available, even before an LSP attaches)
			vim.keymap.set("n", "<leader>dt", cycle_diag_mode, { desc = "LSP: cycle diagnostics display" })
			vim.keymap.set("n", "<leader>dv", function()
				-- Quick flip: full virtual text on/off (stays on signs mode otherwise)
				if diag_mode == "full" then
					apply_diag_mode("signs")
					vim.notify("Diagnostics: signs (virtual text off)", vim.log.levels.INFO)
				else
					apply_diag_mode("full")
					vim.notify("Diagnostics: full (virtual text on)", vim.log.levels.INFO)
				end
			end, { desc = "LSP: toggle virtual text" })
			vim.keymap.set("n", "<leader>dq", function()
				if diag_mode == "quiet" then
					apply_diag_mode("signs")
					vim.notify("Diagnostics: signs", vim.log.levels.INFO)
				else
					apply_diag_mode("quiet")
					vim.notify("Diagnostics: quiet (hidden)", vim.log.levels.INFO)
				end
			end, { desc = "LSP: toggle diagnostics quiet/on" })

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

					-- Docs / info (cursor must be ON the symbol, e.g. "length" not "()")
					local function hover()
						local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/hover" })
						if #clients == 0 then
							vim.notify(
								"No LSP hover for this buffer. Check :LspInfo (is ts_ls attached?)",
								vim.log.levels.WARN
							)
							return
						end
						vim.lsp.buf.hover({
							border = "rounded",
							max_width = 80,
							max_height = 20,
							-- silent=false so empty results still give feedback in newer nvim
							silent = false,
						})
					end
					map("n", "K", hover, "LSP: hover docs")
					map("n", "<C-k>", hover, "LSP: hover docs")
					map("i", "<C-s>", function()
						vim.lsp.buf.signature_help({ border = "rounded" })
					end, "LSP: signature help")
					map("n", "gs", function()
						vim.lsp.buf.signature_help({ border = "rounded" })
					end, "LSP: signature help")

					-- Navigation
					map("n", "gd", vim.lsp.buf.definition, "LSP: go to definition")
					map("n", "gD", vim.lsp.buf.declaration, "LSP: go to declaration")
					map("n", "gi", vim.lsp.buf.implementation, "LSP: implementations")
					map("n", "gr", vim.lsp.buf.references, "LSP: references")
					map("n", "gy", vim.lsp.buf.type_definition, "LSP: type definition")

					-- Refactor
					map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: rename")
					map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "LSP: code action")

					-- Diagnostics navigation / inspect (work even when display is quiet)
					map("n", "[d", function()
						vim.diagnostic.jump({ count = -1, float = true })
					end, "Prev diagnostic")
					map("n", "]d", function()
						vim.diagnostic.jump({ count = 1, float = true })
					end, "Next diagnostic")
					map("n", "<leader>d", function()
						vim.diagnostic.open_float(nil, { border = "rounded", source = true, focus = false })
					end, "Line diagnostics (float)")
					map("n", "<leader>dl", function()
						vim.diagnostic.setloclist({ open = true })
					end, "Diagnostics → location list")
					map("n", "<leader>dqf", function()
						vim.diagnostic.setqflist({ open = true })
					end, "Diagnostics → quickfix")

					-- Format buffer with LSP (if server supports it)
					map("n", "<leader>f", function()
						vim.lsp.buf.format({ async = true })
					end, "LSP: format buffer")

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
			-- typescript-language-server shebang is `#!/usr/bin/env node`.
			-- On WSL, /usr/bin/node is often v12 (too old → SyntaxError on `??`) while
			-- nvm provides a modern node. Pin cmd to a Node >= 18 when available.
			local function resolve_node()
				local function major(bin)
					if not bin or bin == "" or vim.fn.executable(bin) ~= 1 then
						return 0
					end
					local r = vim.system({ bin, "-p", "process.versions.node" }, { text = true }):wait()
					if r.code ~= 0 then
						return 0
					end
					return tonumber((r.stdout or ""):match("(%d+)")) or 0
				end

				local path_node = vim.fn.exepath("node")
				if major(path_node) >= 18 then
					return path_node
				end

				-- Newest nvm install that is modern enough
				local nvm_nodes = vim.fn.glob(vim.fn.expand("~/.nvm/versions/node/*/bin/node"), false, true)
				table.sort(nvm_nodes)
				for i = #nvm_nodes, 1, -1 do
					if major(nvm_nodes[i]) >= 18 then
						return nvm_nodes[i]
					end
				end

				return path_node ~= "" and path_node or "node"
			end

			local tsls = vim.fn.exepath("typescript-language-server")
			local ts_init = { hostInfo = "neovim" }
			-- Only load Vue plugin when it is actually installed (missing path breaks JS hover).
			local vue_plugin = "/usr/local/lib/node_modules/@vue/typescript-plugin"
			if vim.fn.isdirectory(vue_plugin) == 0 then
				vue_plugin = vim.fn.expand("~/.nvm/versions/node/*/lib/node_modules/@vue/typescript-plugin")
				local matches = vim.fn.glob(vue_plugin, false, true)
				vue_plugin = (type(matches) == "table" and matches[1]) or nil
			end
			if vue_plugin and vim.fn.isdirectory(vue_plugin) == 1 then
				ts_init.plugins = {
					{
						name = "@vue/typescript-plugin",
						location = vue_plugin,
						languages = { "javascript", "typescript", "vue" },
					},
				}
			end

			vim.lsp.config("ts_ls", {
				-- Force modern node so the server doesn't die under system Node 12.
				cmd = { resolve_node(), tsls, "--stdio" },
				init_options = ts_init,
				filetypes = {
					"javascript",
					"javascriptreact",
					"javascript.jsx",
					"typescript",
					"typescriptreact",
					"typescript.tsx",
					"vue",
				},
				-- Prefer project roots so single-file / home-as-root doesn't go weird
				root_markers = {
					"tsconfig.json",
					"jsconfig.json",
					"package.json",
					".git",
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
			if has_bin("vscode-json-language-server") then
				enable[#enable + 1] = "jsonls"
			end
			if #enable > 0 then
				vim.lsp.enable(enable)
			end
		end,
	},
}
