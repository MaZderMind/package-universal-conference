local Runner = {}
Runner.__index = Runner

function Runner.new(loader)
	self = {}
	setmetatable(self, Runner)

	self.loader = loader

	return self
end

function Runner:run(which)
	local module = self.loader.modules[which]
	if not module then
		print("WARNING", "single-runner: current module not available:", which)
		return
	end

	local ok, err = pcall(module.render)

	if not ok then
		print("ERROR", "in render-call", err)
		return
	end
end

return Runner
