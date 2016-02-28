local M = {}

local function feeder()
    return CONFIG.background_graphics
end

local function is_enabled()
    return #CONFIG.background_graphics > 0
end

local generator = util.generator(feeder)
local background_rotation_interval = CONFIG.background_rotation_interval
if background_rotation_interval < 1 then
    background_rotation_interval = 1
end

local graphic
local next_graphic
local valid_until = 0

M.tick = function()
    local color = CONFIG.background_color.rgba_table
    gl.clear(unpack(color))

    if not is_enabled() then
        return
    end

    local now = sys.now()

    if next_graphic == nil and now > valid_until then
        next_graphic = generator.next()
        print("scheduling next background-graphic", next_graphic.file.asset_name)
    end

    if next_graphic and next_graphic.file:get_surface():state() == 'loaded' then
        print("background-graphic is loaded, swapping graphics", next_graphic.file.asset_name)
        graphic = next_graphic.file:get_surface()
        next_graphic = nil
        valid_until = now + background_rotation_interval
    end

    if graphic == nil then
        return
    end

    local t = now / 10

    local x = math.sin(t/1) * 7 + 7
    local y = math.cos(t/0.6) * 10
    local z = math.cos(t/3) * 1
    local dx = math.sin(t/6) * 100
    local dy = math.sin(t/6) * 5 - 30
    local s = 1.3

    local width, height = graphic:size()

    local fov = math.atan2(HEIGHT, WIDTH*2) * 360 / math.pi
    gl.perspective(fov, WIDTH/2, HEIGHT/2, -WIDTH,
                               WIDTH/2, HEIGHT/2, 0)

    gl.pushMatrix()
    gl.translate(width/2, height/2)
    gl.scale(s, s)
    gl.rotate(x, 1, 0, 0)
    gl.rotate(y, 0, 1, 0)
    gl.rotate(z, 0, 0, 1)
    gl.translate(-width/2, -height/2)
    gl.translate(dx, dy)
    util.draw_correct(graphic, 0, 0, WIDTH, HEIGHT, 1)
    gl.popMatrix()
end

return M
