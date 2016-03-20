local M = {}

local tools             = require "lib/tools"
local time              = require "lib/time"
local config            = require "lib/config"

local showhide_speed = 0.05
local visibility = 0
local target = 0
local restore = sys.now() + 1
local hide_angle = 110 -- degrees
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

local image, next_image, last_image
local image_transition_duration = 2*60 --seconds
local image_in_transition = false
local image_transition_counter = 0
local valid_until = 0

local function images_init()
	if not CONFIG.sidebar_images then return end

	print("sidebar_images changed, loading all images")
	for idx, image in pairs(CONFIG.sidebar_images) do
		if image.file.type ~= "video" then
			image.file.load()
		end
	end
end
config.on_option_changed(
	{'sidebar_images'},
	images_init
)
images_init()


local function images_feeder()
	return CONFIG.sidebar_images
end
local generator = util.generator(images_feeder)

local function draw_images(usable_area)
	local now = sys.now()

	if next_image == nil and now > valid_until then
		next_image = generator.next()
		valid_until = sys.now() + next_image.duration

		print("image display time is over, selecting next image", next_image.file.asset_name) 
		if next_image.type == "video" then
			print("re-loading video", next_image.file.asset_name)
			next_image.file.unload()
			next_image.file.load()
		end
	end

	if not image_in_transition and next_image and next_image.file:get_surface():state() == 'loaded' then
		if image == nil then
			print("next image is loaded and no current image -> jumping transition", next_image.file.asset_name)
			image = next_image
			next_image = nil
		else
			print("next image is loaded, starting transition", next_image.file.asset_name)

			image_in_transition = true
			image_transition_counter = image_transition_duration
		end
	end

	gl.pushMatrix()

	local width = 0
	if image ~= nil then
		local ox1, oy1, ox2, oy2 = util.scale_into(
			usable_area.w, usable_area.h, image.file.get_surface():size())

		width = ox2 - ox1
	end

	if image_in_transition then
		gl.translate(
			width/2,
			0
		)
		gl.rotate(image_transition_counter / image_transition_duration * 90 - 90, 0, 1, 0)
		gl.translate(
			-width/2,
			0
		)

		if image_transition_counter > 0 then
			print("running out-transition", image_transition_counter)
			image_transition_counter = image_transition_counter - 1
		elseif image_transition_counter < 0 then
			print("running in-transition", image_transition_counter)
			image_transition_counter = image_transition_counter + 1
		end

		if image_transition_counter == 0 then
			if next_image ~= nil then
				print("out-transition finished, swapping images")
				image = next_image
				next_image = nil

				image_transition_counter = -image_transition_duration
			else
				print("in-transition finished, ending transition cycle. image valid for", image.duration)
				image_in_transition = false
			end
		end
	end

	if image ~= nil then
		util.draw_correct(
			image.file.get_surface(), 
			usable_area.x,
			usable_area.y,
			usable_area.x + usable_area.w,
			usable_area.y + usable_area.h,
			1
		)
	end

	gl.popMatrix()
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
			place.x - padh - 2.5,
			place.y - padv - 2.5,
			place.x + w + padh + 2.5,
			place.y + sz + padv,
			1
		)
	end

	local usable_area_images = {
		x=0;
		y=0;
		w=usable_area.w;
		h=usable_area.h;
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
	elseif visibility > 0.999 then
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
