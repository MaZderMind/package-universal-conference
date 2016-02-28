gl.setup(1920, 1080)

font = resource.load_font("data_silkscreen.ttf")

local M = {}

function M.can_schedule()
    return true
end

function M.prepare()
    state = {}
    duration = 5
    return duration, state
end

function M.render(time, duration, state)
    font:write(120, 320, string.format("Hello: %0.2f", time), 100, 1,1,1,1)
end

function M.dispose(state)
    -- nop
end

return M
