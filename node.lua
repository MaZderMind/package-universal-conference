local scale = 1.0 -- downscale. 1.0 is fullHD, 2 is half of fullHD

gl.setup(1920 / scale, 1080 / scale)
WIDTH = WIDTH * scale
HEIGHT = HEIGHT * scale

node.set_flag "slow_gc"
util.init_hosted()

util.loaders.pkm = resource.load_image

pp(CONFIG)

------

local ModuleLoader = require "loader"
local Runner = require "runner"
local Scheduler = require "scheduler"

local Fadeout = require "fadeout"
local Scroller = require "scroller"

local utils = require "utils"

------

local modules = ModuleLoader()
local runner = Runner(modules)
local scheduler = Scheduler(runner, modules)

local fadeout = Fadeout()
local scroller = Scroller()

------

function node.render()
    fadeout.tick()

    runner.tick()
    utils.reset_view()
    scheduler.tick()

    scroller.tick()
end
