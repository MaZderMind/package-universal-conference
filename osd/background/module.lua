local Logger = require("lib/logger")
local logger = Logger.new("osd/background")

local tools = require("lib/tools")
local config = require("lib/config")
local M = {}

local shaders = {
    multisample = resource.create_shader[[
        uniform sampler2D Texture;
        varying vec2 TexCoord;
        uniform vec4 Color;
        uniform float x, y, s;
        void main() {
            vec2 texcoord = TexCoord * vec2(s, s) + vec2(x, y);
            vec4 c1 = texture2D(Texture, texcoord);
            vec4 c2 = texture2D(Texture, texcoord + vec2(0.0002, 0.0002));
            gl_FragColor = (c2+c1)*0.5 * Color;
        }
    ]], 
    simple = resource.create_shader[[
        uniform sampler2D Texture;
        varying vec2 TexCoord;
        uniform vec4 Color;
        uniform float x, y, s;
        void main() {
            gl_FragColor = texture2D(Texture, TexCoord * vec2(s, s) + vec2(x, y)) * Color;
        }
    ]], 
}

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

local graphic, next_graphic
local valid_until = 0
local from, to
local frame = 0

local function init()
    logger:info("background_graphics changed, loading all images")
    for idx, graphic in pairs(CONFIG.background_graphics) do
        if graphic.type ~= "video" then
            graphic.file.load_and_watch()
        end
    end
end
config.on_option_changed(
    {'background_graphics'},
    init
)
init()


local function draw_still()
    local surface = graphic.file:get_surface()
    util.draw_correct(surface, 0, 0, WIDTH, HEIGHT, 1)
end

local function lerp(s, e, t)
    return s + t * (e-s)
end

local function draw_kenburns(t)
    local surface = graphic.file:get_surface()

    local w, h = surface:size()
    local multisample = w / WIDTH > 0.8 or h / HEIGHT > 0.8
    local shader = multisample and shaders.multisample or shaders.simple

    shader:use{
        x = lerp(from.x, to.x, t);
        y = lerp(from.y, to.y, t);
        s = lerp(from.s, to.s, t);
    }
    util.draw_correct(surface, 0, 0, WIDTH, HEIGHT)
    shader:deactivate()
end

local function draw_swing(now)
    local surface = graphic.file:get_surface()
    local t = now/100

    local w, h = surface:size()
    local multisample = w / WIDTH > 0.8 or h / HEIGHT > 0.8
    local shader = multisample and shaders.multisample or shaders.simple

    local x = math.sin(t/2) * 10 + 7
    local y = math.cos(2) * 10
    local z = 0 -- math.cos(t/3) * 1
    local dx = math.sin(t/6) * 100
    local dy = math.sin(t/6) * 5 - 30
    local s = 1.3

    gl.pushMatrix()
    gl.translate(w/2, h/2)
    gl.scale(s, s)
    gl.rotate(x, 1, 0, 0)
    gl.rotate(y, 0, 1, 0)
    gl.rotate(z, 0, 0, 1)
    gl.translate(-w/2, -h/2)
    gl.translate(dx, dy)
    util.draw_correct(surface, 0, 0, WIDTH, HEIGHT)
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
        if next_graphic.type == "video" then
            logger:debug("re-loading video", next_graphic.file.asset_name)
            next_graphic.file.unload()
            next_graphic.file.load()
        end
    end

    if next_graphic and next_graphic.file:get_surface():state() == 'loaded' then
        logger:debug("background-graphic is loaded, swapping graphics", next_graphic.file.asset_name)

        graphic = next_graphic
        next_graphic = nil
        valid_until = now + background_rotation_interval

        if CONFIG.background_animating == 'kenburns' then
            local paths = {
                {from = {x=0.0,  y=0.0,  s=1.0 }, to = {x=0.08, y=0.08, s=0.9 }},
                {from = {x=0.05, y=0.0,  s=0.93}, to = {x=0.03, y=0.03, s=0.97}},
                {from = {x=0.02, y=0.05, s=0.91}, to = {x=0.01, y=0.05, s=0.95}},
                {from = {x=0.07, y=0.05, s=0.91}, to = {x=0.04, y=0.03, s=0.95}},
            }

            local path = paths[math.random(1, #paths)]

            to, from = path.to, path.from
            if math.random() >= 0.5 then
                to, from = from, to
            end
        end
    end

    if graphic == nil then
        return
    end

    if CONFIG.background_animating == 'kenburns' and from and to then
        draw_kenburns( (valid_until - now) / background_rotation_interval)
    elseif CONFIG.background_animating == 'swing' then
        draw_swing(frame)
        frame = frame + 1
    else
        draw_still()
    end
end

return M
