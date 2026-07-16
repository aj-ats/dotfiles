return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"folke/lazydev.nvim",
				ft = "lua",
				opts = {
					library = {
						{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
					},
				},
			},
		},
		config = function()
			-- Built-in completion menu behavior (nvim 0.11+)
			vim.opt.completeopt = { "menu", "menuone", "noselect", "popup" }

			-- Signs / underlines for errors (IntelliSense red squiggles)
			vim.diagnostic.config({
				virtual_text = { spacing = 2, prefix = "●" },
				severity = true,
				underline = true,
				update_in_insert = false,
				severity = { border = "rounded", source = true },
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

					-- Hover docs (VS Code "peek type / docs")
					-- Default neovim maps K; we also map Ctrl-k because that's what you tried.
					map("n", "K", function()
						vim.lsp.buf.hover({ border = "rounded", max_width = 80, max_height = 20 })
					end, "LSP: hover docs")
					map("n", "<C-k>", function()
						vim.lsp.buf.hover({ border = "rounded", max_width = 80, max_height = 20 })
					end, "LSP: hover docs")

					-- Signature help while writing a call: foo(|)
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

					-- Refactor / actions
					map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: rename")
					map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "LSP: code action")

					-- Diagnostics
					map("n", "[d", function()
						vim.diagnostic.jump({ count = -1, float = true })
					end, "Prev diagnostic")
					map("n", "]d", function()
						vim.diagnostic.jump({ count = 1, float = true })
					end, "Next diagnostic")
					map("n", "<leader>d", vim.diagnostic.open_float, "Line diagnostics")

					-- Built-in LSP completion (no nvim-cmp needed)
					if client:supports_method("textDocument/completion") then
						vim.lsp.completion.enable(true, client.id, bufnr, {
							autotrigger = true, -- popup as you type
						})
					end
				end,
			})

			-- Language servers (on PATH). Enable only here — not in lazy.lua / init.lua.
			-- Python: basedpyright only (do not also enable pyright).
			-- JS/TS/Vue: ts_ls. Lua: lua_ls.
			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						workspace = {
							checkThirdParty = false,
							library = vim.api.nvim_get_runtime_file("", true),
						},
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

			vim.lsp.enable({
				"lua_ls",
				"basedpyright",
				"ts_ls",
			})

		end,
	},
}
