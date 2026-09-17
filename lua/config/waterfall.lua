-- Animated ASCII waterfall on empty nvim start.
-- :Waterfall to play it again. Any key dismisses.

local M = {}

local state = {
	buf = nil,
	win = nil,
	timer = nil,
	tick = 0,
	ns = nil,
	key_ns = nil,
	saved = nil,
	open = false,
}

-- Classic dashboard NEOVIM wordmark (box drawing).
local LOGO_WIDE = {
	"███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
	"████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
	"██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
	"██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
	"██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
	"╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
}

-- Compact Neovim N (fits short/narrow terminals).
local LOGO_N = {
	"█▙   ▟█▙",
	"██▙ ▟███",
	"█▝█▟█▘▐█",
	"█ ▝█▘ ▟█",
}

local RIVER = { "~", "≈", "~", "∼", "≋", "~", "≈" }
local POOL = { "~", "≈", "~", "⁓", "﹏", "≈", "~" }

local function fract(n)
	return n - math.floor(n)
end

local function noise(x, y)
	return fract(math.sin(x * 127.1 + y * 311.7) * 43758.5453)
end

local function editor_size()
	local w = vim.o.columns
	local h = math.max(8, vim.o.lines - vim.o.cmdheight)
	return w, h
end

local function strw(s)
	return vim.fn.strchars(s)
end

local function strch(s, i)
	return vim.fn.strcharpart(s, i - 1, 1)
end

local function set_hls()
	local h = vim.api.nvim_set_hl
	h(0, "WaterfallFall", { fg = "#7aa2f7" })
	h(0, "WaterfallFallDeep", { fg = "#3d59a1" })
	h(0, "WaterfallFoam", { fg = "#c0caf5", bold = true })
	h(0, "WaterfallSplash", { fg = "#7dcfff" })
	h(0, "WaterfallRiver", { fg = "#7dcfff" })
	h(0, "WaterfallPool", { fg = "#2ac3de" })
	h(0, "WaterfallPoolDeep", { fg = "#1a4a6e" })
	h(0, "WaterfallMist", { fg = "#565f89" })
	h(0, "WaterfallRock", { fg = "#414868" })
	h(0, "WaterfallRockHi", { fg = "#565f89" })
	h(0, "WaterfallMoss", { fg = "#73daca" })
	h(0, "WaterfallMossDark", { fg = "#3d7a80" })
	h(0, "WaterfallHint", { fg = "#565f89", italic = true })
	h(0, "WaterfallMtFar", { fg = "#3b4261" })
	h(0, "WaterfallMtEdge", { fg = "#565f89" })
	h(0, "WaterfallSnow", { fg = "#c0caf5" })
	h(0, "WaterfallSnowDim", { fg = "#a9b1d6" })
	h(0, "WaterfallLogo", { fg = "#9ece6a", bold = true })
	h(0, "WaterfallLogoDim", { fg = "#73daca" })
	h(0, "WaterfallLogoBright", { fg = "#c0caf5", bold = true })
	h(0, "WaterfallCursor", { fg = "#1a1b26", bg = "#1a1b26", blend = 100, nocombine = true })
end

local function put(grid, hl, width, height, x, y, ch, group)
	x = math.floor(x + 0.5)
	y = math.floor(y + 0.5)
	if y < 1 or y > height or x < 1 or x > width then
		return
	end
	grid[y][x] = ch
	hl[y][x] = group
end

local function blit(grid, hl, width, height, x, y, text, group)
	for i = 1, strw(text) do
		put(grid, hl, width, height, x + i - 1, y, strch(text, i), group)
	end
end

local function make_grid(width, height)
	local grid, hl = {}, {}
	for y = 1, height do
		grid[y] = {}
		hl[y] = {}
		for x = 1, width do
			grid[y][x] = " "
		end
	end
	return grid, hl
end

local function pick_logo(width, height)
	local wide = strw(LOGO_WIDE[1])
	if width >= wide + 2 and height >= 26 then
		return LOGO_WIDE
	end
	if width >= wide + 2 and height >= 22 then
		return { LOGO_WIDE[1], LOGO_WIDE[2], LOGO_WIDE[5], LOGO_WIDE[6] }
	end
	if width >= strw(LOGO_N[1]) + 2 and height >= 18 then
		return LOGO_N
	end
	return { "NEOVIM" }
end

local function geometry(width, height)
	local logo = pick_logo(width, height)
	local logo_h = #logo
	local cx = math.floor(width / 2)
	local sky_h = logo_h + 1
	local river_h = (height >= 22) and 2 or 1
	local pool_h = math.max(3, math.floor(height * 0.14))
	local ledge_y = sky_h + river_h + 1
	local pool_y = height - pool_h
	local fall_h = pool_y - ledge_y - 1
	if fall_h < 5 then
		-- keep the fall readable; shrink logo to a single line if needed
		logo = { "NEOVIM" }
		logo_h = 1
		sky_h = 2
		ledge_y = sky_h + river_h + 1
		pool_y = height - math.max(3, pool_h)
		fall_h = pool_y - ledge_y - 1
	end
	local lip_w = math.max(12, math.floor(width * 0.34))
	local pool_w = math.max(lip_w + 10, math.floor(width * 0.58))
	return {
		cx = cx,
		logo = logo,
		logo_h = logo_h,
		sky_h = sky_h,
		river_h = river_h,
		pool_h = pool_h,
		ledge_y = ledge_y,
		pool_y = pool_y,
		fall_h = fall_h,
		lip_w = lip_w,
		pool_w = pool_w,
		lip_l = cx - math.floor(lip_w / 2),
		lip_r = cx + math.ceil(lip_w / 2),
		pool_l = cx - math.floor(pool_w / 2),
		pool_r = cx + math.ceil(pool_w / 2),
	}
end

-- Slow, smooth canyon walls — no salt-and-pepper jag.
local function edges_at(g, y)
	local t = 0
	if g.pool_y > g.ledge_y then
		t = (y - g.ledge_y) / (g.pool_y - g.ledge_y)
	end
	t = math.max(0, math.min(1, t))
	local left = g.lip_l + (g.pool_l - g.lip_l) * t
	local right = g.lip_r + (g.pool_r - g.lip_r) * t
	local jag_l = math.sin(y * 0.23) * 0.9
	local jag_r = math.sin(y * 0.21 + 1.4) * 0.9
	return math.floor(left + jag_l), math.floor(right + jag_r)
end

local function sheet_wave(y, tick)
	local phase = y * 0.16 - tick * 0.18
	-- slow S-curve down the gorge; amplitude in cells
	local wave = math.sin(phase) * 2.8 + math.sin(y * 0.06 - tick * 0.10 + 1.05) * 1.4
	local lean = math.cos(phase)
	return wave, lean
end

-- ASCII triangle peak. Spaces are left alone so farther ranges show through.
local function draw_peak(grid, hl, width, height, px, peak_y, base_y, half_w, snow_h, far, tick)
	px = math.floor(px + 0.5)
	peak_y = math.max(1, math.floor(peak_y))
	base_y = math.floor(base_y)
	half_w = math.max(3, half_w)
	if peak_y >= base_y then
		return
	end
	local edge_hl = far and "WaterfallMtFar" or "WaterfallMtEdge"
	local snow_hl = far and "WaterfallSnowDim" or "WaterfallSnow"
	local last = math.min(base_y, height - 1)

	for y = peak_y, last do
		local t = (y - peak_y) / (base_y - peak_y)
		local half = (y == peak_y) and 0.5 or (t * half_w)
		local l = math.floor(px - half)
		local r = math.floor(px + half)
		if r <= l then
			r = l + 1
		end
		for x = l, r do
			local from_top = y - peak_y
			local ch, group
			if x == l then
				ch, group = "/", edge_hl
			elseif x == r then
				ch, group = "\\", edge_hl
			elseif from_top <= snow_h then
				local spark = ((x + math.floor(tick / 5)) % 6 == 0)
				if spark then
					ch, group = "*", snow_hl
				elseif from_top == 0 then
					ch, group = "^", snow_hl
				else
					ch, group = (far and "·" or "^"), snow_hl
				end
			end
			-- interior stays empty so overlapping peaks read as a clean range
			if ch then
				put(grid, hl, width, height, x, y, ch, group)
			end
		end
	end
end

local function draw_mountains(grid, hl, width, height, g, tick)
	local base = g.ledge_y
	local span = math.max(3, base - 1)
	-- { center x as fraction of width, height 0-1 of sky, half-width fraction }
	-- Stay off the center so the NEOVIM mark sits in a valley.
	local far = {
		{ 0.05, 0.48, 0.08 },
		{ 0.13, 0.64, 0.09 },
		{ 0.88, 0.60, 0.09 },
		{ 0.97, 0.42, 0.07 },
	}
	local near = {
		{ 0.05, 1.00, 0.13 },
		{ 0.14, 0.78, 0.09 },
		{ 0.87, 0.76, 0.09 },
		{ 0.96, 1.00, 0.13 },
	}

	local function place(peaks, is_far)
		for _, p in ipairs(peaks) do
			local px = p[1] * width
			local peak_y = base - math.floor(p[2] * span)
			local half_w = p[3] * width
			local snow_h = is_far and 1 or math.max(1, math.floor((base - math.max(1, peak_y)) * 0.30))
			draw_peak(grid, hl, width, height, px, peak_y, base, half_w, snow_h, is_far, tick)
		end
	end

	place(far, true)
	place(near, false)
end

local function draw_mist(grid, hl, width, height, g, tick)
	local n = math.max(6, math.floor(width * 0.18))
	for i = 1, n do
		local x = 1 + math.floor(noise(i * 3.1, 2.7) * (width - 1))
		local drift = math.floor(math.sin(tick * 0.06 + i * 0.4) * 2)
		local y = 1 + ((i * 17 + math.floor(tick / 4) + drift) % math.max(1, g.sky_h))
		if noise(i, math.floor(tick / 3)) > 0.4 then
			put(grid, hl, width, height, x, y, (i % 2 == 0) and "·" or ".", "WaterfallMist")
		end
	end
end

local function draw_logo(grid, hl, width, height, g, tick)
	local lines = g.logo
	local w = strw(lines[1])
	local x0 = math.max(1, math.floor((width - w) / 2) + 1)
	local y0 = 1
	for i, line in ipairs(lines) do
		local lw = strw(line)
		for c = 1, lw do
			local ch = strch(line, c)
			if ch ~= " " then
				-- sheen sweeping left → right across the mark
				local shine = (c + math.floor(tick / 3)) % math.max(10, w)
				local group
				if shine < 2 then
					group = "WaterfallLogoBright"
				elseif c <= 10 then
					group = "WaterfallLogo" -- the N
				else
					group = "WaterfallLogoDim"
				end
				put(grid, hl, width, height, x0 + c - 1, y0 + i - 1, ch, group)
			end
		end
	end
end

local function draw_river(grid, hl, width, height, g, tick)
	for row = 0, g.river_h - 1 do
		local y = g.sky_h + 1 + row
		local shrink = row
		local l = g.lip_l - 3 + shrink
		local r = g.lip_r + 3 - shrink
		for x = l, r do
			-- traveling horizontal flow into the lip
			local ch = RIVER[1 + ((x + tick) % #RIVER)]
			local group = (row == g.river_h - 1) and "WaterfallFoam" or "WaterfallRiver"
			put(grid, hl, width, height, x, y, ch, group)
		end
	end
	local y = g.ledge_y
	for x = g.lip_l - 2, g.lip_r + 2 do
		put(grid, hl, width, height, x, y, "▄", "WaterfallRockHi")
	end
	-- water going over: foam, then the streams pick up below
	for x = g.lip_l, g.lip_r do
		local ch = RIVER[1 + ((x + tick + 1) % #RIVER)]
		if (x + tick) % 3 == 0 then
			ch = "░"
		end
		put(grid, hl, width, height, x, y, ch, "WaterfallFoam")
	end
end

local function draw_cliffs(grid, hl, width, height, g)
	local bottom = height - 1
	for y = g.ledge_y, bottom do
		local left, right = edges_at(g, y)
		for x = 1, left do
			local dist = left - x
			local n = noise(math.floor(x / 2), math.floor(y / 2))
			local ch, group
			if dist <= 0 then
				ch = "▓"
				group = "WaterfallRockHi"
			elseif dist == 1 then
				ch = (n > 0.5) and ":" or "▓"
				group = (n > 0.5) and "WaterfallMoss" or "WaterfallRockHi"
			else
				ch = (n > 0.62) and "▓" or "█"
				group = (n > 0.8) and "WaterfallRockHi" or "WaterfallRock"
			end
			put(grid, hl, width, height, x, y, ch, group)
		end
		for x = right, width do
			local dist = x - right
			local n = noise(math.floor((x + 9) / 2), math.floor(y / 2))
			local ch, group
			if dist <= 0 then
				ch = "▓"
				group = "WaterfallRockHi"
			elseif dist == 1 then
				ch = (n > 0.5) and ":" or "▓"
				group = (n > 0.5) and "WaterfallMoss" or "WaterfallRockHi"
			else
				ch = (n > 0.62) and "▓" or "█"
				group = (n > 0.8) and "WaterfallRockHi" or "WaterfallRock"
			end
			put(grid, hl, width, height, x, y, ch, group)
		end
	end
end

-- One sheet of water: a traveling sine wave sways the curtain,
-- foam bands slide down, streams lean with the wave. No TV-static noise.
local function draw_fall(grid, hl, width, height, g, tick)
	for y = g.ledge_y + 1, g.pool_y - 1 do
		local left, right = edges_at(g, y)
		local wave, lean = sheet_wave(y, tick)
		local shift = math.floor(wave + 0.5)
		local fl = left + 1 + shift
		local fr = right - 1 + shift
		if fr - fl < 6 then
			local m = math.floor((left + right) / 2)
			fl, fr = m - 3, m + 3
		end
		local mid = (fl + fr) / 2
		local half = math.max(1, (fr - fl) / 2)
		local near_top = y - g.ledge_y
		local near_bot = g.pool_y - y
		local foam_band = math.sin(y * 0.46 - tick * 0.40)

		for x = fl, fr do
			local dist = math.abs(x - mid) / half
			if dist <= 1 then
				local ch, group
				local vein = math.sin((x - shift) * 0.85) > 0.35
				local scroll = (y - tick) % 5
				if near_bot <= 2 then
					ch = (foam_band > 0) and "░" or "▒"
					group = "WaterfallSplash"
				elseif near_top <= 1 then
					ch = "║"
					group = "WaterfallFoam"
				elseif dist > 0.88 then
					-- only the veil leans; the core stays vertical so it reads as falling water
					if lean > 0.25 then
						ch = "╲"
					elseif lean < -0.25 then
						ch = "╱"
					else
						ch = "┆"
					end
					group = "WaterfallFallDeep"
				elseif foam_band > 0.72 and dist < 0.55 and (vein or scroll == 1) then
					ch = "░"
					group = "WaterfallFoam"
				elseif vein then
					ch = (scroll < 2) and "┃" or "║"
					group = "WaterfallFall"
				else
					ch = (scroll == 0) and "┃" or "│"
					group = (dist > 0.65) and "WaterfallFallDeep" or "WaterfallFall"
				end
				put(grid, hl, width, height, x, y, ch, group)
			end
		end
	end
end

local function draw_splash(grid, hl, width, height, g, tick)
	local left, right = edges_at(g, g.pool_y - 1)
	local _, lean = sheet_wave(g.pool_y - 1, tick)
	local shift = math.floor(sheet_wave(g.pool_y - 1, tick) + 0.5)
	for x = left + 1 + shift, right - 1 + shift do
		local pulse = math.sin(x * 0.35 + tick * 0.4)
		if pulse > -0.2 then
			put(grid, hl, width, height, x, g.pool_y - 1, (pulse > 0.5) and "░" or "≈", "WaterfallFoam")
		end
		if pulse > 0.65 then
			put(grid, hl, width, height, x, g.pool_y - 2, "·", "WaterfallSplash")
		end
	end
	-- a few droplets kicking off the impact, following the lean
	for i = 1, 10 do
		local life = (tick + i * 5) % 12
		if life < 7 then
			local sx = g.cx + math.floor(((i % 7) - 3) * 2 + lean * 2)
			local sy = g.pool_y - 1 - math.floor(math.abs(math.sin(tick * 0.3 + i)) * 3)
			local ch = (life < 3) and "°" or "·"
			put(grid, hl, width, height, sx, sy, ch, "WaterfallSplash")
		end
	end
end

local function draw_pool(grid, hl, width, height, g, tick)
	local last = height - 1
	for row = 0, g.pool_h do
		local y = g.pool_y + row
		if y > last then
			break
		end
		local widen = row * 2
		local l = g.pool_l - widen
		local r = g.pool_r + widen
		for x = l, r do
			local ch, group
			if row == 0 then
				ch = POOL[1 + ((x + tick) % #POOL)]
				group = "WaterfallFoam"
			elseif row == 1 then
				ch = POOL[1 + ((x - math.floor(tick / 1)) % #POOL)]
				group = "WaterfallPool"
			else
				local n = noise(math.floor(x / 3), math.floor(y / 2) + math.floor(tick / 6))
				ch = (n > 0.5) and "░" or "▒"
				group = "WaterfallPoolDeep"
			end
			put(grid, hl, width, height, x, y, ch, group)
		end
	end
	-- expanding ripple on the impact line
	local ripple_r = 3 + (tick % math.max(5, math.floor(g.pool_w / 5)))
	for x = g.cx - ripple_r, g.cx + ripple_r do
		put(grid, hl, width, height, x, g.pool_y, "~", "WaterfallSplash")
	end
end

local function draw_hint(grid, hl, width, height)
	local text = "press any key"
	local x = math.max(1, math.floor((width - #text) / 2) + 1)
	blit(grid, hl, width, height, x, height, text, "WaterfallHint")
end

local function render_frame(width, height, tick)
	local grid, hl = make_grid(width, height)
	local g = geometry(width, height)
	draw_mountains(grid, hl, width, height, g, tick)
	draw_mist(grid, hl, width, height, g, tick)
	draw_logo(grid, hl, width, height, g, tick)
	draw_cliffs(grid, hl, width, height, g)
	draw_river(grid, hl, width, height, g, tick)
	draw_fall(grid, hl, width, height, g, tick)
	draw_splash(grid, hl, width, height, g, tick)
	draw_pool(grid, hl, width, height, g, tick)
	draw_hint(grid, hl, width, height)
	return grid, hl
end

local function grid_to_buf(grid, hl, width, height)
	local lines = {}
	local spans = {}
	for y = 1, height do
		local parts = {}
		local row_spans = {}
		local byte = 0
		local cur, start_b = nil, 0
		for x = 1, width do
			local ch = grid[y][x] or " "
			local group = hl[y][x]
			if group ~= cur then
				if cur then
					row_spans[#row_spans + 1] = { start_b, byte, cur }
				end
				cur = group
				start_b = byte
			end
			parts[#parts + 1] = ch
			byte = byte + #ch
		end
		if cur then
			row_spans[#row_spans + 1] = { start_b, byte, cur }
		end
		lines[y] = table.concat(parts)
		spans[y] = row_spans
	end
	return lines, spans
end

local function paint()
	if not state.open or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
		return
	end
	if not state.win or not vim.api.nvim_win_is_valid(state.win) then
		return
	end
	local width, height = editor_size()
	pcall(vim.api.nvim_win_set_config, state.win, {
		relative = "editor",
		row = 0,
		col = 0,
		width = width,
		height = height,
	})
	local grid, hl = render_frame(width, height, state.tick)
	local lines, spans = grid_to_buf(grid, hl, width, height)
	vim.bo[state.buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.api.nvim_buf_clear_namespace(state.buf, state.ns, 0, -1)
	for y, row in ipairs(spans) do
		for _, s in ipairs(row) do
			vim.api.nvim_buf_add_highlight(state.buf, state.ns, s[3], y - 1, s[1], s[2])
		end
	end
	vim.bo[state.buf].modifiable = false
	pcall(vim.api.nvim_win_set_cursor, state.win, { 1, 0 })
end

local function restore_opts()
	local s = state.saved
	if not s then
		return
	end
	vim.o.laststatus = s.laststatus
	vim.o.showtabline = s.showtabline
	vim.o.cmdheight = s.cmdheight
	vim.o.guicursor = s.guicursor
	vim.o.showmode = s.showmode
	vim.o.ruler = s.ruler
	state.saved = nil
end

function M.close()
	if not state.open then
		return
	end
	state.open = false
	if state.timer then
		pcall(function()
			state.timer:stop()
			state.timer:close()
		end)
		state.timer = nil
	end
	if state.key_ns then
		pcall(vim.on_key, nil, state.key_ns)
		state.key_ns = nil
	end
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		pcall(vim.api.nvim_win_close, state.win, true)
	end
	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
	end
	state.win, state.buf = nil, nil
	restore_opts()
end

local function should_autoload()
	if vim.g.waterfall_disable then
		return false
	end
	if vim.fn.argc(-1) > 0 then
		return false
	end
	if vim.g.started_with_stdin then
		return false
	end
	if vim.o.insertmode then
		return false
	end
	if vim.g.diff or vim.wo.diff then
		return false
	end
	if #vim.api.nvim_list_uis() == 0 then
		return false
	end
	return true
end

function M.open()
	if state.open then
		M.close()
	end
	set_hls()
	state.ns = state.ns or vim.api.nvim_create_namespace("waterfall")
	state.tick = 0
	state.saved = {
		laststatus = vim.o.laststatus,
		showtabline = vim.o.showtabline,
		cmdheight = vim.o.cmdheight,
		guicursor = vim.o.guicursor,
		showmode = vim.o.showmode,
		ruler = vim.o.ruler,
	}
	vim.o.laststatus = 0
	vim.o.showtabline = 0
	vim.o.showmode = false
	vim.o.ruler = false
	vim.o.cmdheight = 0
	vim.o.guicursor = "a:WaterfallCursor"

	local width, height = editor_size()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].buflisted = false
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "waterfall"
	vim.bo[buf].modifiable = false

	local ok, win = pcall(vim.api.nvim_open_win, buf, true, {
		relative = "editor",
		row = 0,
		col = 0,
		width = width,
		height = height,
		style = "minimal",
		border = "none",
		zindex = 250,
		focusable = true,
		noautocmd = true,
	})
	if not ok then
		pcall(vim.api.nvim_buf_delete, buf, { force = true })
		restore_opts()
		return
	end
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].foldcolumn = "0"
	vim.wo[win].colorcolumn = ""
	vim.wo[win].cursorline = false
	vim.wo[win].cursorcolumn = false
	vim.wo[win].list = false
	vim.wo[win].wrap = false
	vim.wo[win].statuscolumn = ""
	vim.wo[win].fillchars = "eob: "
	vim.wo[win].winhighlight = "Normal:Normal,EndOfBuffer:Normal,MsgArea:Normal"

	state.buf = buf
	state.win = win
	state.open = true

	paint()

	local timer = vim.uv.new_timer()
	state.timer = timer
	timer:start(0, 50, vim.schedule_wrap(function()
		if not state.open then
			return
		end
		state.tick = state.tick + 1
		paint()
	end))

	state.key_ns = vim.api.nvim_create_namespace("waterfall_keys")
	vim.on_key(function(key)
		if not state.open then
			return
		end
		M.close()
		if key == "q" or key == "Q" then
			return ""
		end
	end, state.key_ns)

	vim.api.nvim_create_autocmd({ "VimResized" }, {
		buffer = buf,
		callback = function()
			if state.open then
				paint()
			end
		end,
	})
	vim.api.nvim_create_autocmd({ "WinClosed", "BufWipeout" }, {
		buffer = buf,
		once = true,
		callback = function()
			M.close()
		end,
	})
end

function M.setup()
	vim.api.nvim_create_autocmd("StdinReadPre", {
		group = vim.api.nvim_create_augroup("WaterfallStdin", { clear = true }),
		callback = function()
			vim.g.started_with_stdin = true
		end,
	})
	vim.api.nvim_create_autocmd("UIEnter", {
		group = vim.api.nvim_create_augroup("WaterfallStart", { clear = true }),
		once = true,
		callback = function()
			vim.schedule(function()
				if should_autoload() then
					M.open()
				end
			end)
		end,
	})
	vim.api.nvim_create_user_command("Waterfall", function()
		M.open()
	end, { desc = "Play the startup waterfall animation" })
end

function M.dump(path, width, height, tick)
	width = width or 80
	height = height or 28
	tick = tick or 12
	local grid, hl = render_frame(width, height, tick)
	local lines = grid_to_buf(grid, hl, width, height)
	if path then
		local f = assert(io.open(path, "w"))
		f:write(table.concat(lines, "\n"))
		f:write("\n")
		f:close()
	end
	return table.concat(lines, "\n")
end

return M
