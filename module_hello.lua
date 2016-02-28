gl.setup(1920, 1080)

font = resource.load_font("data_silkscreen.ttf")

local M = {}

function M.can_schedule()
    return true
end

function M.prepare(options)
    state = {
        text = options.text or 'Nothing';
        bgcol = options.bgcol or {0,0,0,1};
    }

    duration = 5
    return duration, state
end

function M.render(time, duration, state)
    gl.clear(unpack(state.bgcol))
    font:write(120, 320, string.format("Hello %s: %0.2f", state.text, time), 100, 1,1,1,1)
end

function M.dispose(state)
    -- nop
end

return M
