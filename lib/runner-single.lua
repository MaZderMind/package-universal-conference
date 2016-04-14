local Logger = require("lib/logger")
local logger = Logger.new("runner-single")

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
		logger:warn("current module not available:", which)
		return
	end

	local ok, err = pcall(module.render, self.loader.modules)

	if not ok then
		logger:warn("error in render-call", err)
		return
	end
end

return Runner
