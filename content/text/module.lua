gl.setup(1920, 1080)

font = resource.load_font("assets/fonts/silkscreen.ttf")

local M = {}

function M.can_schedule()
    return true
end

function M.prepare()
    state = {}
    duration = 30
    return duration, state
end

function M.render(time, duration, usable_area, state)
    local txt = "Hello"
    local sz = 300

    gl.pushMatrix()
    gl.translate(
        usable_area.x+(usable_area.w)/2,
        usable_area.y+(usable_area.h)/2
    )
    gl.rotate(time / duration * 360 * 5, 0, 1, 0)
    local w = font:width(txt, sz)
    font:write(-w/2, -sz/2, txt, sz, 1,1,1,1)
    gl.popMatrix()
end

function M.dispose(state)
    -- nop
end

return M
