local time = require("lib/time")
local config = require("lib/config")

local M = {}
local showhide_speed = 0.05
local padv = 2.5

local function feeder()
	return CONFIG.scroller_text
end

function M.is_enabled()
	return #CONFIG.scroller_text > 0
end

function M.get_height()
	if M.is_enabled() then
		return CONFIG.scroller_size + CONFIG.scroller_padding + CONFIG.scroller_padding
	else
		return 0
	end
end

local text
config.on_option_changed(
	{'scroller_font', 'scroller_size', 'scroller_speed', 'scroller_color'},
	function()
		text = util.running_text{
			font = CONFIG.scroller_font;
			size = CONFIG.scroller_size;
			speed = CONFIG.scroller_speed;
			color = CONFIG.scroller_color.rgba_table;
			generator = util.generator(feeder)
		}
	end
)

local visibility = 0
local target = 0
local restore = sys.now() + 1

function M.hide(duration)
	target = 0
	restore = sys.now() + duration
end

local function draw(usable_area)
	if type(text) == 'nil' then return nil end

	local bgcolor = CONFIG.scroller_background.rgba_table
	local size = CONFIG.scroller_size

	local bg = resource.create_colored_texture(unpack(bgcolor))

	bg:draw(
		0,
		usable_area.y + usable_area.h - ( visibility * (size - padv - padv) ),
		usable_area.x + usable_area.w,
		usable_area.y + usable_area.h,
		1
	)
	text:draw(
		usable_area.y + usable_area.h - ( visibility * (size + padv) )
	)
end

function M.render(other_osd_modules)
	if sys.now() > restore then
		target = 1
	end

	visibility = visibility * (1-showhide_speed) + target * (showhide_speed)
	if visibility <= 0.01 then
		return
	end

	if type(text) == 'nil' then
		return
	end

	usable_area = {
		x = 0;
		y = 0;
		w = WIDTH;
		h = HEIGHT;
	}

	draw(usable_area)
end


return M
