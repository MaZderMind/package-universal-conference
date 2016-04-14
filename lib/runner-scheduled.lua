local Logger = require("lib/logger")
local logger = Logger.new("runner-scheduled")

local Runner = {}
Runner.__index = Runner

function Runner.new(loader)
	self = {}
	setmetatable(self, Runner)

	self.loader = loader
	self.visuals = {}

	return self
end

function Runner:add(visual)
	table.insert(self.visuals, visual)
end

function Runner:tick(usable_area)
	local now = sys.now()
	local visual = self.visuals[1]

	if not visual or visual.starts > now then
		logger:warn("nothing scheduled")
		return
	end

	local module = self.loader.modules[visual.module]
	if not module then
		logger:warn("scheduler-runner: current module not available:", visual.module)
		table.remove(self.visuals, 1)

		return self:tick(usable_area)
	end

	if visual.starts + visual.duration < now then
		logger:info("visual finished & removed", visual.title)
		pcall(module.dispose, visual.state)
		table.remove(self.visuals, 1)

		return self:tick(usable_area)
	end

	local time = now - visual.starts
	local ok, err = pcall(module.render, time, visual.duration, usable_area, visual.state)

	if not ok then
		logger:warn("error in render-call", err)
		table.remove(self.visuals, 1)
		return
	end
end

return Runner
