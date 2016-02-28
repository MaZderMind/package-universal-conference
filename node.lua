local scale = 1.0 -- downscale. 1.0 is fullHD, 2 is half of fullHD

gl.setup(1920 / scale, 1080 / scale)
WIDTH = WIDTH * scale
HEIGHT = HEIGHT * scale

node.set_flag "slow_gc"
util.init_hosted()

--util.loaders.pkm = resource.load_image

------

local ModuleLoader = require "tool_loader"
local Runner       = require "tool_runner"
local Scheduler    = require "tool_scheduler"

local Fadeout      = require "tool_fadeout"
local Scroller     = require "tool_scroller"

local utils        = require "tool_utils"

------

local modules   = ModuleLoader()
local runner    = Runner(modules)
local scheduler = Scheduler(runner, modules)

local fadeout   = Fadeout()
local scroller  = Scroller()

------

function node.render()
    scheduler.tick()
    fadeout.tick()
    runner.tick()
    scroller.tick()
end
