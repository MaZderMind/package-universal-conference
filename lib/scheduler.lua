local tools = require("lib/tools")
local time = require("lib/time")

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new(loader, runner)
	self = {}
	setmetatable(self, Scheduler)

	self.loader = loader
	self.runner = runner
	self.playlist_offset = 0

	self.next_visual = sys.now() + 1
	self.next_wake = sys.now()

	return self
end

function Scheduler:enqueue(item)
	local options = item.options or {}
	local ok, duration, state = pcall(self.loader.modules[item.module].prepare, options)

	local visual = {
		starts = self.next_visual - 1;
		duration = duration;
		title = item.title or item.module;
		module = item.module;
		state = state;
		options = options;
	}

	if not ok then
		pcall(self.loader.modules[item.module].dispose, state)
		local error = duration
		print("ERROR", "failed to prepare " .. visual.title .. ": " .. error)
		return
	end

	self.next_visual = self.next_visual + duration - 1
	self.next_wake   = self.next_visual - 3
	print("INFO", "about to schedule visual ", visual.title)
	self.runner:add(visual)
end

function Scheduler:tick()
	if sys.now() < self.next_wake then
		return
	end

	local item, can_schedule
	repeat
		item, self.playlist_offset = tools.cycled(CONFIG.playlist, self.playlist_offset)
		can_schedule = true
		if item.chance then
			can_schedule = math.random() < (item.chance / 100)
		end
		if item.hours then
			local hours = {}
			for h in string.gmatch(item.hours, "%S+") do
				hours[tonumber(h)] = true
			end
			local hour, min = time.walltime()
			if not hours[hour] then
				can_schedule = false
			end
		end
		if not self.loader.modules[item.module] then
			--print("INFO", "module not available", item.module)
			can_schedule = false
		elseif not self.loader.modules[item.module].can_schedule(item.options) then
			print("INFO", "module cannot be scheduled", item.module)
			can_schedule = false
		end
	until can_schedule
	self:enqueue(item)
end

return
Scheduler