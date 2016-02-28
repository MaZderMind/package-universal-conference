local utils = require "tool_utils"

function Runner(modules)
    local visuals = {}

    local function add(visual)
        table.insert(visuals, visual)
    end

    local function tick()
        local now = sys.now()
        local visual = visuals[1]

        if not visual or visual.starts > now then
            print("ERROR", "nothing scheduled")
            return
        end
        local module = modules[visual.module]
        if not module then 
            print("WARNING", "module unloaded")
            table.remove(visuals, 1)

            return tick()
        end

        if visual.starts + visual.duration < now then
            print("INFO", "visual finished & removed", visual.title)
            pcall(module.dispose, visual.state)
            table.remove(visuals, 1)

            return tick()
        end

        local time = now - visual.starts
        utils.reset_view()

        local ok, err = pcall(module.render, time, visual.duration, visual.state)

        if not ok then
            print("ERROR", "in render-call", err)
            table.remove(visuals, 1)
        end
    end

    return {
        tick = tick;
        add = add;
    }
end

return Runner
