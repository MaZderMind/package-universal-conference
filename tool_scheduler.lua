local json = require "json"
local utils = require "tool_utils"
local time = require "tool_time"
local runner = require "tool_runner"
local modules = require "tool_module_loader"

local playlist_offset = 0

local next_visual = sys.now() + 1
local next_wake = sys.now()

local function enqueue(item)
    local options = item.options or {}
    local ok, duration, state = pcall(modules[item.module].prepare, options)

    local visual = {
        starts = next_visual - 1;
        duration = duration;
        title = item.title or item.module;
        module = item.module;
        state = state;
        options = options;
    }

    if not ok then
        pcall(modules[item.module].dispose, state)
        print("ERROR", "failed to prepare " .. visual.title)
        return
    end

    next_visual = next_visual + duration - 1
    next_wake = next_visual - 3
    print("INFO", "about to schedule visual ", visual.title)
    runner.add(visual)
end

util.data_mapper{
    ["scheduler/enqueue"] = function(raw)
        enqueue(json.decode(raw))
    end
}

local function tick()
    if sys.now() < next_wake then
        return
    end

    local item, can_schedule
    repeat
        item, playlist_offset = utils.cycled(CONFIG.playlist, playlist_offset)
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
        if not modules[item.module] then
            print("INFO", "module not available", item.module)
            can_schedule = false
        elseif not modules[item.module].can_schedule(item.options) then
            print("INFO", "module cannot be scheduled", item.module)
            can_schedule = false
        end
    until can_schedule
    enqueue(item)
end

return {
    tick = tick;
}
