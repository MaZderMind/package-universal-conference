gl.setup(1920, 1080)

font = resource.load_font("data_silkscreen.ttf")

local M = {}

function M.can_schedule()
    return true
end

-- The prepare function is called with the options given in the
-- playlist json file. This function is called once each time
-- the module is about to be scheduled. 
-- The function should return a duration (in seconds) as well
-- as a value that is later available in the run function.
function M.prepare(playlist_options)
    duration = 5
    run_options = {
        text = playlist_options.text or 'Nothing'
    }
    return duration, run_options
end

-- This function is running in a coroutine. It gets started
-- a few seconds before the module should be visible.
-- duration and options are the values returned by prepare.
-- fn is a table containing useful functions that can be
-- used to control the coroutine.
function M.run(duration, options, fn)
    -- prepare stuff here

    -- suspend co-routine until the actual display should be started
    fn.wait_t(0)


    -- loop in co-routine until the duration is over
    for now in fn.upto_t(duration) do
        -- co-routine is resumed (and loop-body is executed)
        -- once for every frame
        font:write(120, 320, "Hello " .. options.text, 100, 1,1,1,1)
    end

    return true
end

return M
