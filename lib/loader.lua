local Loader = {}
Loader.__index = Loader

function Loader.new(folder)
	self = {}
	setmetatable(self, Loader)

	self.folder = folder
	self.modules = {}
	self.keys = {}

	self:init_watcher()

	return self
end

function Loader:init_watcher()
	node.event("content_update", function(filename)
		local module_name = self:module_name_from_filename(filename)
		if module_name then
			self:module_update(module_name, assert(loadstring(resource.load_file(filename), "=" .. filename))())
		end
	end)
	node.event("content_remove", function(filename)
		local module_name = self:module_name_from_filename(filename)
		if module_name then
			self:module_unload(module_name)
		end
	end)
end

function Loader:module_name_from_filename(filename)
	return filename:match(self.folder .. "/(.*)%/module.lua")
end

function Loader:module_unload(module_name)
	if self.modules[module_name] and self.modules[module_name].unload then
		self.modules[module_name].unload()
	end
	self.modules[module_name] = nil
	node.gc()
end

function Loader:module_update(module_name, module)
	self:module_unload(module_name)
	self.modules[module_name] = module
	node.gc()
end

return Loader
