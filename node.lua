local scale = 1.0 -- downscale. 1.0 is fullHD, 2 is half of fullHD

gl.setup(1920 / scale, 1080 / scale)
WIDTH = WIDTH * scale
HEIGHT = HEIGHT * scale

node.set_flag "slow_gc"

assert(sys.provides "nested-nodes", "nested nodes feature missing")
node.make_nested()

util.init_hosted()

-- load library classes
local Loader            = require("lib/loader")
local RunnerScheduled   = require("lib/runner-scheduled")
local RunnerSingle      = require("lib/runner-single")
local Scheduler         = require("lib/scheduler")
local Logger            = require("lib/logger")

-- configure debug logging
Logger.debug_global = false
-- Logger.debug_component["osd/sidebar/images"] = true


-- create instances
--- content is scheduled based on a playlist
local content_loader    = Loader.new('content')
local content_runner    = RunnerScheduled.new(content_loader)
local content_scheduler = Scheduler.new(content_loader, content_runner)

--- osd elements run always and decide theirselfs if they need to draw sth.
local osd_loader        = Loader.new('osd')
local osd_runner        = RunnerSingle.new(osd_loader)


local tools             = require "lib/tools"

function node.render()
	tools.reset_view()

	osd_runner:run('background')

	local usable_area = {
		x = 0;
		y = 0;
		w = WIDTH;
		h = HEIGHT;
	}

	if osd_loader.modules['scroller'] then
		usable_area.h = usable_area.h - osd_loader.modules['scroller'].get_height()
	end

	if osd_loader.modules['sidebar'] then
		usable_area.w = usable_area.w - osd_loader.modules['sidebar'].get_width()
	end

	content_scheduler:tick()
	content_runner:tick(usable_area)

	osd_runner:run('scroller')
	osd_runner:run('sidebar')
	osd_runner:run('clock')
end
