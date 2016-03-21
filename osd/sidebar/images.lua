local Images = {}
Images.__index = Images

function Images.new(feeder)
	self = {}
	setmetatable(self, Images)

	self.generator = util.generator(feeder)
	self.image = nil
	self.next_image = nil

	self.image_transition_duration = 2 --seconds
	self.phase_offset = 0.1 -- offset in the change-point (between 0..1) due to perspective

	self.image_in_transition = false
	self.transition_until = 0
	self.valid_until = 0

	return self
end

function Images:draw(usable_area, visibility)
	local now = sys.now()

	if self.image ~= nil and self.image.duration == 0 then
		-- image configured for endless display

		util.draw_correct(
			self.image.file.get_surface(), 
			usable_area.x,
			usable_area.y,
			usable_area.x + usable_area.w,
			usable_area.y + usable_area.h
		)

		return
	end

	if self.next_image == nil and now > self.valid_until then
		self.next_image = self.generator.next()
		self.valid_until = now + self.next_image.duration + self.image_transition_duration

		print("image display time is over, selecting next image", self.next_image.file.asset_name) 
		if self.next_image.type == "video" then
			print("re-loading video", self.next_image.file.asset_name)
			self.next_image.file.unload()
			self.next_image.file.load()
		end
	end

	if not self.image_in_transition and self.next_image and self.next_image.file:get_surface():state() == 'loaded' then
		if self.image == nil then
			print("next image is loaded and no current image -> jumping transition", self.next_image.file.asset_name)
			self.image = self.next_image
			self.next_image = nil
		else
			print("next image is loaded, starting transition", self.next_image.file.asset_name)

			self.image_in_transition = true
			self.transition_until = now + self.image_transition_duration
		end
	end

	gl.pushMatrix()

	local width = 0
	if self.image ~= nil then
		local ox1, oy1, ox2, oy2 = util.scale_into(
			usable_area.w, usable_area.h, self.image.file.get_surface():size())

		width = ox2 - ox1
	end

	local transition_phase = 0

	if visibility < 1 then
		transition_until = now - 1
	end

	if self.image_in_transition then
		gl.translate(
			width/2 + usable_area.x,
			0
		)

		transition_phase = 1 - (self.transition_until - now) / self.image_transition_duration
		local rot = transition_phase * 180
		if self.next_image == nil then
			rot = rot + 180
		end
		gl.rotate(rot, 0, 1, 0)
		gl.translate(
			-width/2 - usable_area.x,
			0
		)

		if transition_phase > 0.5+self.phase_offset and self.next_image ~= nil then
			print("out-transition finished, swapping images")
			self.image = self.next_image
			self.next_image = nil
		elseif transition_phase > 1 then
			print("in-transition finished, ending transition cycle. image valid for", self.image.duration)
			self.image_in_transition = false
		end
	end

	if self.image ~= nil then
		local alpha = math.sqrt(math.abs(math.cos((transition_phase - self.phase_offset) * math.pi)))
		util.draw_correct(
			self.image.file.get_surface(), 
			usable_area.x,
			usable_area.y,
			usable_area.x + usable_area.w,
			usable_area.y + usable_area.h,
			alpha
		)
	end

	gl.popMatrix()
end

return Images
