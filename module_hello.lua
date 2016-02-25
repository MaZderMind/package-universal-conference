gl.setup(1024, 768)

font = resource.load_font("silkscreen.ttf")

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
