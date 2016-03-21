local M = {}

local tools             = require "lib/tools"
local time              = require "lib/time"
local config            = require "lib/config"
local Images            = require "osd/sidebar/images"

local showhide_speed = 0.03
local visibility = 0
local target = 0
local restore = sys.now() + 1
local hide_angle = 120 -- degrees
local frame = 0

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

local function images_init()
	print("sidebar images changed, loading all images")

	if CONFIG.sidebar_primary_images then
		for idx, image in pairs(CONFIG.sidebar_primary_images) do
			if image.file.type ~= "video" then
				image.file.mipmap = true
				image.file.load_and_watch()
			end
		end
	end
	if CONFIG.sidebar_secondary_images then
		for idx, image in pairs(CONFIG.sidebar_secondary_images) do
			if image.file.type ~= "video" then
				image.file.mipmap = true
				image.file.load_and_watch()
			end
		end
	end
end
config.on_option_changed(
	{'sidebar_primary_images', 'sidebar_secondary_images'},
	images_init
)
images_init()


local function primary_images_feeder()
	return CONFIG.sidebar_primary_images
end

local function secondary_images_feeder()
	return CONFIG.sidebar_secondary_images
end

local primary_images, secondary_images
local function draw_images(usable_area)
	if primary_images == nil then
		primary_images = Images.new(primary_images_feeder)
	end

	if secondary_images == nil then
		secondary_images = Images.new(secondary_images_feeder)
	end

	usable_area.h = CONFIG.sidebar_primary_images_height
	primary_images:draw(usable_area, visibility)

	usable_area.y = usable_area.h + CONFIG.sidebar_images_padding
	usable_area.h = CONFIG.sidebar_secondary_images_height
	secondary_images:draw(usable_area, visibility)
end

local function draw_clock(usable_area)
	local font = CONFIG.clock_font
	local color = CONFIG.clock_color.rgba_table

	local txt = time.walltime_text()

	local sz = CONFIG.clock_size
	local w = font:width(txt, sz)

	local place = {
		x = (usable_area.w - w) / 2 + usable_area.x;
		y = (usable_area.h - sz) / 2 + usable_area.y;
	}

	font:write(place.x, place.y, txt, sz, unpack(color))
end

local function draw(usable_area)
	local bgimg = CONFIG.sidebar_background_image
	local bgcolor = CONFIG.sidebar_background

	gl.pushMatrix()

	gl.translate(
		usable_area.w + usable_area.x,
		0
	)

	gl.rotate(hide_angle * (1-visibility), 0, 1, 0)

	gl.translate(
		0 - usable_area.w,
		usable_area.y
	)

	if bgcolor then
		local bg = resource.create_colored_texture(unpack(bgcolor.rgba_table))
		bg:draw(
			0,
			0,
			usable_area.w,
			usable_area.h
		)
	end

	if bgimg then
		bgimg.draw(
			0,
			0,
			usable_area.w,
			usable_area.h
		)
	end

	local padding = 50
	local usable_area_images = {
		x=padding;
		y=padding;
		w=usable_area.w - padding - padding;
		h=usable_area.h - padding - padding;
	}
	local usable_area_clock = nil

	if CONFIG.clock_placement == 'sidebar' then
		local clock_area_height = 200

		usable_area_images.h = usable_area_images.h - clock_area_height

		usable_area_clock = {
			x=0;
			y=usable_area.h - clock_area_height;
			w=usable_area.w;
			h=clock_area_height;
		}

		draw_clock(usable_area_clock)
	end

	draw_images(usable_area_images)

	gl.popMatrix()

	frame = frame+1
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

	local usable_area = {
		x = WIDTH - CONFIG.sidebar_width;
		y = 0;
		w = CONFIG.sidebar_width;
		h = HEIGHT;
	}

	if other_osd_modules['scroller'] then
		usable_area.h = usable_area.h - other_osd_modules['scroller'].get_height()
	end

	draw(usable_area)
end

return M
