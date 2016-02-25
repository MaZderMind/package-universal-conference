function ModuleLoader()
    local modules = {}

    local function module_name_from_filename(filename)
        return filename:match("module_(.*)%.lua")
    end

    local function module_unload(module_name)
        if modules[module_name] and modules[module_name].unload then
            modules[module_name].unload()
        end
        modules[module_name] = nil
        node.gc()
    end

    local function module_update(module_name, module)
        module_unload(module_name)
        modules[module_name] = module
        node.gc()
    end

    node.event("content_update", function(filename)
        local module_name = module_name_from_filename(filename)
        if module_name then
            module_update(module_name, assert(loadstring(resource.load_file(filename), "=" .. filename))())
        end
    end)
    node.event("content_delete", function(filename)
        local module_name = module_name_from_filename(filename)
        if module_name then
            module_unload(module_name)
        end
    end)

    return modules
end

return ModuleLoader
