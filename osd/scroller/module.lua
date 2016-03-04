local time = require("lib/time")
local config = require("lib/config")

local M = {}

local function feeder()
	return CONFIG.scroller_text
end

local function is_enabled()
	return #CONFIG.scroller_text > 0
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
local showhide_speed = 0.05

function M.hide(duration)
	target = 0
	restore = sys.now() + duration
end

local function draw()
	if type(text) == 'nil' then return nil end

	local bgcolor = CONFIG.scroller_background.rgba_table
	local size = CONFIG.scroller_size

	local bg = resource.create_colored_texture(unpack(bgcolor))
	local padv = 2.5
	if visibility > 0.01 then
		bg:draw(0, HEIGHT-(size + padv + padv), WIDTH, HEIGHT, 1)
		text:draw(HEIGHT - visibility * (size + padv))
	end
end

function M.render()
	if sys.now() > restore then
		target = 1
	end

	visibility = visibility * (1-showhide_speed) + target * (showhide_speed)
	if is_enabled() then
		draw()
	end
end


return M
