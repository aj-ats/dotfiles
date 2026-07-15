return {
	"nvim-tree/nvim-tree.lua",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFocus", "NvimTreeFindFile" },
	keys = {
		{
			"<leader>e",
			function()
				require("nvim-tree.api").tree.toggle({ focus = true, find_file = true })
			end,
			desc = "Toggle file tree",
			mode = "n",
		},
	},
	config = function()
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1

		-- Layout: tree (left) + preview (right), centered like Telescope
		local layout = {
			tree_ratio = 0.38,
			max_width = 140,
			max_height = 42,
		}

		local function dims()
			local total_w = math.min(layout.max_width, math.floor(vim.o.columns * 0.9))
			local height = math.min(layout.max_height, math.floor(vim.o.lines * 0.75))
			local tree_w = math.max(28, math.floor(total_w * layout.tree_ratio))
			local prev_w = total_w - tree_w - 1
			local row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1)
			local col = math.max(0, math.floor((vim.o.columns - total_w) / 2))
			return {
				total_w = total_w,
				height = height,
				tree_w = tree_w,
				prev_w = prev_w,
				row = row,
				col = col,
			}
		end

		local function tree_float_config()
			local d = dims()
			return {
				relative = "editor",
				border = "rounded",
				width = d.tree_w,
				height = d.height,
				row = d.row,
				col = d.col,
				title = " files ",
				title_pos = "center",
			}
		end

		-- ---- Hover preview (Telescope-style) ----
		local preview = {
			win = nil,
			buf = nil,
			path = nil,
		}

		local function close_preview()
			if preview.win and vim.api.nvim_win_is_valid(preview.win) then
				pcall(vim.api.nvim_win_close, preview.win, true)
			end
			if preview.buf and vim.api.nvim_buf_is_valid(preview.buf) then
				pcall(vim.api.nvim_buf_delete, preview.buf, { force = true })
			end
			preview.win, preview.buf, preview.path = nil, nil, nil
		end

		local function is_probably_binary(path)
			local f = io.open(path, "rb")
			if not f then
				return true
			end
			local chunk = f:read(512) or ""
			f:close()
			return chunk:find("\0", 1, true) ~= nil
		end

		local function read_preview_lines(path, max_lines)
			max_lines = max_lines or 400
			local lines = {}
			local f = io.open(path, "r")
			if not f then
				return { "-- cannot read file --" }
			end
			for line in f:lines() do
				-- avoid huge lines freezing UI
				if #line > 400 then
					line = line:sub(1, 400) .. "…"
				end
				lines[#lines + 1] = line
				if #lines >= max_lines then
					lines[#lines + 1] = "… (preview truncated)"
					break
				end
			end
			f:close()
			if #lines == 0 then
				return { "-- empty file --" }
			end
			return lines
		end

		local function ensure_preview_win()
			local d = dims()
			local cfg = {
				relative = "editor",
				border = "rounded",
				width = d.prev_w,
				height = d.height,
				row = d.row,
				col = d.col + d.tree_w + 1,
				style = "minimal",
				focusable = false,
				zindex = 60,
				title = " preview ",
				title_pos = "center",
			}

			if preview.win and vim.api.nvim_win_is_valid(preview.win) then
				vim.api.nvim_win_set_config(preview.win, cfg)
				return
			end

			preview.buf = vim.api.nvim_create_buf(false, true)
			vim.bo[preview.buf].bufhidden = "wipe"
			vim.bo[preview.buf].buftype = "nofile"
			vim.bo[preview.buf].swapfile = false
			vim.bo[preview.buf].modifiable = true

			preview.win = vim.api.nvim_open_win(preview.buf, false, cfg)
			vim.wo[preview.win].number = true
			vim.wo[preview.win].relativenumber = false
			vim.wo[preview.win].cursorline = false
			vim.wo[preview.win].wrap = false
			vim.wo[preview.win].signcolumn = "no"
			vim.wo[preview.win].winhighlight = "Normal:Normal,FloatBorder:FloatBorder"
		end

		local function show_preview(path)
			if not path or path == "" or vim.fn.isdirectory(path) == 1 then
				close_preview()
				return
			end
			if not vim.uv.fs_stat(path) then
				close_preview()
				return
			end
			if preview.path == path and preview.win and vim.api.nvim_win_is_valid(preview.win) then
				return -- already showing this file
			end

			ensure_preview_win()
			if not preview.buf or not vim.api.nvim_buf_is_valid(preview.buf) then
				return
			end

			local lines
			local ft
			if is_probably_binary(path) then
				lines = { "-- binary file (no preview) --", path }
				ft = "text"
			else
				lines = read_preview_lines(path)
				ft = vim.filetype.match({ filename = path }) or ""
			end

			vim.bo[preview.buf].modifiable = true
			vim.api.nvim_buf_set_lines(preview.buf, 0, -1, false, lines)
			-- syntax without full filetype plugins (lightweight)
			if ft ~= "" then
				pcall(vim.api.nvim_buf_set_option, preview.buf, "filetype", ft)
			end
			vim.bo[preview.buf].modifiable = false
			vim.bo[preview.buf].readonly = true
			preview.path = path

			-- title with filename
			local name = vim.fn.fnamemodify(path, ":t")
			pcall(vim.api.nvim_win_set_config, preview.win, {
				title = " " .. name .. " ",
				title_pos = "center",
			})
		end

		local function preview_node_under_cursor()
			local ok, api = pcall(require, "nvim-tree.api")
			if not ok then
				return
			end
			local node = api.tree.get_node_under_cursor()
			if not node then
				close_preview()
				return
			end
			-- node.absolute_path for files; skip directories / specials
			if node.type == "file" or (node.absolute_path and vim.fn.isdirectory(node.absolute_path) == 0) then
				show_preview(node.absolute_path)
			else
				close_preview()
			end
		end

		-- Debounce so holding j/k stays smooth
		local timer = nil
		local function schedule_preview()
			if timer then
				timer:stop()
				timer:close()
				timer = nil
			end
			timer = vim.uv.new_timer()
			timer:start(60, 0, function()
				vim.schedule(function()
					if timer then
						timer:stop()
						timer:close()
						timer = nil
					end
					preview_node_under_cursor()
				end)
			end)
		end

		require("nvim-tree").setup({
			hijack_cursor = true,
			view = {
				float = {
					enable = true,
					quit_on_focus_loss = false,
					open_win_config = tree_float_config,
				},
				width = 40,
			},
			renderer = {
				group_empty = true,
				indent_markers = {
					enable = true,
				},
				icons = {
					web_devicons = {
						file = { enable = true, color = true },
						folder = { enable = false, color = true },
					},
					show = {
						file = true,
						folder = true,
						folder_arrow = true,
						git = true,
					},
					glyphs = {
						default = "",
						symlink = "",
						folder = {
							arrow_closed = "",
							arrow_open = "",
							default = "",
							open = "",
							empty = "",
							empty_open = "",
							symlink = "",
						},
						git = {
							unstaged = "✗",
							staged = "✓",
							unmerged = "",
							renamed = "➜",
							untracked = "★",
							deleted = "",
							ignored = "◌",
						},
					},
				},
			},
			filters = {
				dotfiles = false,
			},
			actions = {
				open_file = {
					quit_on_open = true,
				},
			},
			update_focused_file = {
				enable = true,
			},
			on_attach = function(bufnr)
				local api = require("nvim-tree.api")
				local function opts(desc)
					return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
				end

				-- default mappings
				api.config.mappings.default_on_attach(bufnr)

				-- preview updates as you move
				vim.api.nvim_create_autocmd({ "CursorMoved" }, {
					buffer = bufnr,
					callback = schedule_preview,
				})

				-- first preview when tree opens / gains focus
				vim.api.nvim_create_autocmd({ "BufEnter" }, {
					buffer = bufnr,
					callback = function()
						vim.schedule(schedule_preview)
					end,
				})

				-- clean up when tree buffer unloads
				vim.api.nvim_create_autocmd({ "BufWipeout", "BufUnload" }, {
					buffer = bufnr,
					callback = close_preview,
				})

				-- optional: Tab still forces preview (native + our float)
				vim.keymap.set("n", "<Tab>", function()
					preview_node_under_cursor()
				end, opts("Hover preview"))
			end,
		})

		-- Close preview whenever tree is closed via API/toggle
		local api = require("nvim-tree.api")
		local Event = api.events.Event
		api.events.subscribe(Event.TreeClose, close_preview)
		api.events.subscribe(Event.TreeAttachedPost, function()
			vim.schedule(schedule_preview)
		end)
		api.events.subscribe(Event.TreeRendered, function()
			vim.schedule(schedule_preview)
		end)
	end,
}
