local scale = 1.0 -- downscale. 1.0 is fullHD, 2 is half of fullHD

gl.setup(1920 / scale, 1080 / scale)
WIDTH = WIDTH * scale
HEIGHT = HEIGHT * scale

node.set_flag "slow_gc"
util.init_hosted()
pp(CONFIG)

------

local Background   = require "tool_background"
local Runner       = require "tool_runner"
local Scheduler    = require "tool_scheduler"
local Scroller     = require "tool_scroller"

local utils = require "tool_utils"

function node.render()
    utils.reset_view()

    Scheduler.tick()
    Background.tick()
    Runner.tick()
    Scroller.tick()
end
