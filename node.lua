local scale = 1.0 -- downscale. 1.0 is fullHD, 2 is half of fullHD

gl.setup(1920 / scale, 1080 / scale)
WIDTH = WIDTH * scale
HEIGHT = HEIGHT * scale

node.set_flag "slow_gc"
util.init_hosted()

--util.loaders.pkm = resource.load_image

------

local Runner       = require "tool_runner"
local Scheduler    = require "tool_scheduler"
local Scroller     = require "tool_scroller"

------

function node.render()
    Scheduler.tick()
    Runner.tick()
    Scroller.tick()
end
