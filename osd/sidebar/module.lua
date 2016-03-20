local M = {}

local showhide_speed = 0.05
local visibility = 0
local target = 0
local restore = sys.now() + 1

local hide_angle = 120

function M.is_enabled()
	return CONFIG.sidebar_width ~= nil and CONFIG.sidebar_width > 0
end

function M.get_width()
	if M.is_enabled() then
		return CONFIG.sidebar_width * visibility -- need correct 3D-trig calculation here
	else
		return 0
	end
end

function M.hide(duration)
	target = 0
	restore = sys.now() + duration
end

util.data_mapper{
	["sidebar/hide"] = function()
		target = 0
		restore = 0
	end;
	["sidebar/show"] = function()
		target = 1
	end;
}

local bg = resource.create_colored_texture(1,1,0,0.75)
local function draw(usable_area)
	gl.pushMatrix()

	gl.translate(
		usable_area.w,
		0
	)

	gl.rotate(hide_angle * (1-visibility), 0, 1, 0)

	bg:draw(
		0 - CONFIG.sidebar_width,
		usable_area.y,
		0,
		usable_area.y + usable_area.h
	)

	gl.popMatrix()
end

function M.render(other_osd_modules)
	if not M.is_enabled() then return end

	if restore > 0 and sys.now() > restore then
		target = 1
	end

	visibility = visibility * (1-showhide_speed) + target * (showhide_speed)
	if visibility <= 0.01 then
		visibility = 0
		return
	elseif visibility > 0.99 then
		visibility = 1
	end

	usable_area = {
		x = 0;
		y = 0;
		w = WIDTH;
		h = HEIGHT;
	}

	if other_osd_modules['scroller'] then
		usable_area.h = usable_area.h - other_osd_modules['scroller'].get_height()
	end

	draw(usable_area)
end

return M
