local utils = require "utils"

function Runner(modules)
    local visuals = {}

    local function add(visual)
        local co = coroutine.create(modules[visual.module].run)

        local success, is_finished = coroutine.resume(co, visual.duration, visual.options, {
            wait_next_frame = function ()
                return coroutine.yield(false)
            end;
            wait_t = function(t)
                while true do
                    local now = coroutine.yield(false)
                    if now >= t then return now end
                end
            end;
            upto_t = function(t) 
                return function()
                    local now = coroutine.yield(false)
                    if now < t then return now end
                end
            end;
        })

        if not success then
            print("ERROR", debug.traceback(co, string.format("cannot start visual: %s", is_finished)))
        elseif not is_finished then
            table.insert(visuals, 1, {
                co = co;
                starts = visual.starts;
            })
        end
    end

    local function tick()
        local now = sys.now()
        for idx = #visuals,1,-1 do -- iterate backwards so we can remove finished visuals
            local visual = visuals[idx]
            utils.reset_view()
            local success, is_finished = coroutine.resume(visual.co, now - visual.starts)
            if not success then
                print("ERROR", debug.traceback(visual.co, string.format("cannot resume visual: %s", is_finished)))
                table.remove(visuals, idx)
            elseif is_finished then
                table.remove(visuals, idx)
            end
        end
    end

    return {
        tick = tick;
        add = add;
    }
end

return Runner
