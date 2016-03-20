local M = {}

local time              = require "lib/time"

local visibility = 0
local target = 0
local restore = sys.now() + 1
local showhide_speed = 0.05

function M.is_enabled()
	return CONFIG.clock_placement ~= nil and CONFIG.clock_placement ~= "none"
end

function M.hide(duration)
	target = 0
	restore = sys.now() + duration
end

local function draw(usable_area)
	local font = CONFIG.clock_font
	local color = CONFIG.clock_color.rgba_table
	local bgimg = CONFIG.clock_background_image
	local bgcolor = CONFIG.clock_background

	local txt = time.walltime_text()

	local sz = CONFIG.clock_size
	local w = font:width(txt, sz)

	local padh, padv = 10, 2.5

	local places = {
		['tl'] = {
			x = usable_area.x + padh;
			y = usable_area.y + padv;
		};
		['tr'] = {
			x = usable_area.x + usable_area.w - w - padh;
			y = usable_area.y + padv;
		};
		['tc'] = {
			x = usable_area.x + (usable_area.w - w) / 2;
			y = usable_area.y + padv
		};
		['br'] = {
			x = usable_area.x + usable_area.w - w - padh;
			y = usable_area.y + usable_area.h - sz - padv;
		};
		['bl'] = {
			x = padh;
			y = usable_area.y + usable_area.h - sz - padv;
		};
		['bc'] = {
			x = usable_area.x + (usable_area.w - w) / 2;
			y = usable_area.y + usable_area.h - sz - padv;
		};
	}
	local place = places[CONFIG.clock_placement]
	if type(place) == 'nil' then return end

	if bgcolor then
		local bg = resource.create_colored_texture(unpack(bgcolor.rgba_table))
		-- additional padding is to cater for font specialities
		bg:draw(
			place.x - padh - 2.5,
			place.y - padv - 2.5,
			place.x + w + padh + 2.5,
			place.y + sz + padv,
			1
		)
	end

	if bgimg then
		bgimg.draw(
			place.x - padh - 2.5,
			place.y - padv - 2.5,
			place.x + w + padh + 2.5,
			place.y + sz + padv,
			1
		)
	end

	font:write(place.x, place.y, txt, sz, unpack(color))
end

function M.render(other_osd_modules)
	if not M.is_enabled() then return end

	if sys.now() > restore then
		target = 1
	end

	visibility = visibility * (1-showhide_speed) + target * (showhide_speed)
	if visibility <= 0.01 then
		return
	end

	local usable_area = {
		x = 0;
		y = 0;
		w = WIDTH;
		h = HEIGHT;
	}

	if other_osd_modules['scroller'] then
		usable_area.h = usable_area.h - other_osd_modules['scroller'].get_height()
	end

	if other_osd_modules['sidebar'] then
		usable_area.w = usable_area.w - other_osd_modules['sidebar'].get_width()
	end

	draw(usable_area)
end

return M
