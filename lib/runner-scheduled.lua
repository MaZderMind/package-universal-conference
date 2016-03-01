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

function Runner:tick()
	local now = sys.now()
	local visual = self.visuals[1]

	if not visual or visual.starts > now then
		print("ERROR", "nothing scheduled")
		return
	end

	local module = self.loader.modules[visual.module]
	if not module then
		print("WARNING", "module unloaded")
		table.remove(self.visuals, 1)

		return self:tick()
	end

	if visual.starts + visual.duration < now then
		print("INFO", "visual finished & removed", visual.title)
		pcall(module.dispose, visual.state)
		table.remove(self.visuals, 1)

		return self:tick()
	end

	local time = now - visual.starts
	local ok, err = pcall(module.render, time, visual.duration, visual.state)

	if not ok then
		print("ERROR", "in render-call", err)
		table.remove(self.visuals, 1)
		return
	end
end

return Runner
