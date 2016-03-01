local tools = require("lib/tools")
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
local animation

local function draw_still()
    local surface = graphic.file:get_surface()
    util.draw_correct(surface, 0, 0, WIDTH, HEIGHT, 1)
end

local function draw_animated(t)
    local surface = graphic.file:get_surface()

    gl.pushMatrix()
    gl.translate(animation.x(t), animation.y(t))
    gl.scale(animation.s(t), animation.s(t))
    util.draw_correct(surface, 0, 0, WIDTH, HEIGHT, 1)
    gl.popMatrix()
end


function M.render()
    local color = CONFIG.background_color.rgba_table
    gl.clear(unpack(color))

    if not is_enabled() then
        return
    end

    local now = sys.now()

    if next_graphic == nil and now > valid_until then
        next_graphic = generator.next()
        next_graphic.file.load()
        print("scheduling next background-graphic", next_graphic.file.asset_name)
    end

    if next_graphic and next_graphic.file:get_surface():state() == 'loaded' then
        print("background-graphic is loaded, swapping graphics", next_graphic.file.asset_name)
        if graphic ~= nil then
            graphic.file.unload()
        end
        graphic = next_graphic
        next_graphic = nil
        valid_until = now + background_rotation_interval

        if CONFIG.background_animating then
            local i = background_rotation_interval
            local splines = {
                x = {
                    {t = now,            val = (-0.05 + math.random() * -0.2) * WIDTH},
                    {t = valid_until,    val = (-0.00 + math.random() * -0.2) * WIDTH},
                };
                y = {
                    {t = now,            val = (-0.03 + math.random() * -0.1) * HEIGHT},
                    {t = valid_until,    val = (-0.00 + math.random() * -0.2) * HEIGHT},
                };
                s = {
                    {t = now,            val = 1.5 + math.random() * 0.2},
                    {t = valid_until,    val = 1.2 + math.random() * 0.2},
                };
            }
            print("calculating animation path")
            animation = {
                x = tools.make_smooth(splines.x);
                y = tools.make_smooth(splines.y);
                s = tools.make_smooth(splines.s);
            }
        end
    end

    if graphic == nil then
        return
    end

    if CONFIG.background_animating and animation then
        draw_animated(now)
    else
        draw_still()
    end
end

return M
