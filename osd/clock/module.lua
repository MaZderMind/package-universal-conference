local M = {}

function M.render()
	local scroller = CONFIG.scroller_size+5
	local font = CONFIG.clock_font
	local color = CONFIG.clock_color.rgba_table
	local bgcolor = CONFIG.clock_background.rgba_table

	local txt = "00:28"

	local sz = CONFIG.clock_size
	local w = font:width(txt, sz)

	local places = {
		['tl'] = {x = 0; y = 0};
		['tr'] = {x = WIDTH-w; y = 0};
		['br'] = {x = WIDTH-w; y = HEIGHT-sz-scroller};
		['bl'] = {x = 0; y = HEIGHT-sz-scroller};
		['tc'] = {x = (WIDTH-w)/2; y = 0};
		['bc'] = {x = (WIDTH-w)/2; y = HEIGHT-sz-scroller};
	}
	local place = places[CONFIG.clock_placement]
	if place then
		local bg = resource.create_colored_texture(unpack(bgcolor))
		bg:draw(place.x, place.y, place.x+w, place.y+sz, 1)
		font:write(place.x, place.y, txt, sz, unpack(color))
	end
end

return M
