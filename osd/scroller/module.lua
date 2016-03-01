local time = require("lib/time")

local M = {}

local function feeder()
	return CONFIG.scroller_text
end

local function is_enabled()
	return #CONFIG.scroller_text > 0
end

local text
util.file_watch("config.json", function(raw)
	local font
	local size
	local speed
	local color

	if
		font ~= CONFIG.scroller_font or
		size ~= CONFIG.scroller_size or
		speed ~= CONFIG.scroller_speed or
		color ~= CONFIG.scroller_color.rgba_table
	then
		font = CONFIG.scroller_font
		size = CONFIG.scroller_size
		speed = CONFIG.scroller_speed
		color = CONFIG.scroller_color.rgba_table

		text = util.running_text{
			font = font;
			size = size;
			speed = speed;
			color = color;
			generator = util.generator(feeder)
		}
	end
end)

local visibility = 0
local target = 0
local restore = sys.now() + 1

function M.hide(duration)
	target = 0
	restore = sys.now() + duration
end

local function draw()
	local bgcolor = CONFIG.scroller_background.rgba_table
	local size = CONFIG.scroller_size

	local bg = resource.create_colored_texture(unpack(bgcolor))
	if visibility > 0.01 then
		bg:draw(0, HEIGHT-(size + 5), WIDTH, HEIGHT, 1)
		text:draw(HEIGHT - visibility * (size + 2.5))
	end
end

local current_speed = 0.05
function M.render()
	if sys.now() > restore then
		target = 1
	end

	visibility = visibility * (1-current_speed) + target * (current_speed)
	if is_enabled() then
		draw()
	end
end


return M
