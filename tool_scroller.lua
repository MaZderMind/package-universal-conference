local json = require "json"
local time = require "tool_time"

font = resource.load_font("data_silkscreen.ttf")

function Scroller()
    local infos = {}
    -- TODO read me from CONFIG
    util.file_watch("data_scroll.txt", function(content)
        infos = {}
        for line in string.gmatch(content.."\n", "([^\n]*)\n") do
            if #line > 0 then
                infos[#infos+1] = line
            end
        end
    end)

    local function feeder()
        local out = {}
        for idx = 1, #infos do
            out[#out+1] = infos[idx]
        end

        return out
    end

    local text = util.running_text{
        font = font;
        size = 40;
        speed = 120;
        color = {1,1,1,.8};
        generator = util.generator(feeder)
    }

    local visibility = 0
    local target = 0
    local restore = sys.now() + 1

    local function hide(duration)
        target = 0
        restore = sys.now() + duration
    end

    local function draw()
        if visibility > 0.01 then
            -- black:draw(0, HEIGHT-45, WIDTH, HEIGHT, visibility/3)
            text:draw(HEIGHT - visibility * 42)
        end
    end

    local current_speed = 0
    local function tick()
        if sys.now() > restore then
            target = 1
        end
        local current_speed = 0.05
        visibility = visibility * (1-current_speed) + target * (current_speed)
        draw()
    end


    return {
        tick = tick;
        hide = hide;
    }
end

return Scroller
