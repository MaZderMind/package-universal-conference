local utils = require "utils"
local json = require "json"
local time = require "time"

function Scheduler(runner, modules)
    local playlist = {}
    local playlist_offset = 0

    -- TODO read me from CONFIG
    util.file_watch("playlist.json", function(raw)
        playlist = json.decode(raw)
        playlist_offset = 0
    end)

    local next_visual = sys.now() + 1
    local next_wake = sys.now()

    local function enqueue(item)
        local ok, duration, options = pcall(modules[item.module].prepare, item.options or {})
        if not ok then
            print("failed to prepare " .. item.module .. ": " .. duration)
            return
        end

        local visual = {
            starts = next_visual - 1;
            duration = duration;
            module = item.module;
            options = options;
        }

        next_visual = next_visual + duration - 1
        next_wake = next_visual - 3
        print("about to schedule visual ", item.module)
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
            item, playlist_offset = utils.cycled(playlist, playlist_offset)
            can_schedule = true
            if item.chance then
                can_schedule = math.random() < item.chance
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
                print("module " .. item.module .. " not available")
                can_schedule = false
            elseif not modules[item.module].can_schedule(item.options) then
                print("module " .. item.module .. " cannot be scheduled")
                can_schedule = false
            end
        until can_schedule
        enqueue(item)
    end

    return {
        tick = tick;
    }
end

return Scheduler
