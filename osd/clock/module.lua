local M = {}

local visibility = 0
local target = 0
local restore = sys.now() + 1
local showhide_speed = 0.05

function M.hide(duration)
	target = 0
	restore = sys.now() + duration
end

function draw()
	if visibility <= 0.01 then
		return
	end

	local scroller = CONFIG.scroller_size+5
	local font = CONFIG.clock_font
	local color = CONFIG.clock_color.rgba_table
	local bgimg = CONFIG.clock_background_image

	local txt = "00:28"

	local sz = CONFIG.clock_size
	local w = font:width(txt, sz)

	local padh, padv = 10, 2.5

	local places = {
		['tl'] = {
			x = padh;
			y = padv;
		};
		['tr'] = {
			x = WIDTH - w - padh;
			y = padv;
		};
		['tc'] = {
			x = (WIDTH - w) / 2;
			y = padv
		};
		['br'] = {
			x = WIDTH - w - padh;
			y = HEIGHT - sz - scroller - padv;
		};
		['bl'] = {
			x = padh;
			y = HEIGHT - sz - scroller - padv;
		};
		['bc'] = {
			x = (WIDTH - w) / 2;
			y = HEIGHT - sz - scroller - padv;
		};
	}
	local place = places[CONFIG.clock_placement]

	if place then
		local bgcolor = CONFIG.clock_background

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
end

function M.render()
	if sys.now() > restore then
		target = 1
	end

	visibility = visibility * (1-showhide_speed) + target * (showhide_speed)
	draw()
end

return M
