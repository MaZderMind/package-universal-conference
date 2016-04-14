local Logger = {}
Logger.__index = Logger

-- class level config
Logger.debug_global = true
Logger.debug_component = {}

local zero_t = sys.now()

function Logger.new(component)
	self = {}
	setmetatable(self, Logger)

	self.component = component
	self.runner = runner

	return self
end

function Logger:print(lvl, ...)
	print(sys.now() - zero_t, lvl, self.component, ...)
end


function Logger:debug(...)
	if Logger.debug_global == false and Logger.debug_component[self.component] ~= true then
		return
	end

	self:print("DEBUG", ...)
end

function Logger:info(...)
	self:print("INFO", ...)
end

function Logger:warn(...)
	self:print("WARN", ...)
end


return Logger
