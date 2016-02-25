gl.setup(1920, 1080)

font = resource.load_font("data_silkscreen.ttf")

local M = {}

function M.can_schedule()
    return true
end

function M.prepare(playlist_options)
    duration = 5
    run_options = {
        text = playlist_options.text or 'Nothing'
    }
    return duration, run_options
end

function M.run(duration, options, fn)
    fn.wait_t(0)

    for now in fn.upto_t(duration) do
        font:write(120, 320, "Hello " .. options.text, 100, 1,1,1,1)
    end

    return true
end

return M
