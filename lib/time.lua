local Logger = require("lib/logger")
local logger = Logger.new("time")

local M = {}

local base_t = os.time() - sys.now()
local midnight

function M.unixtime()
    -- return sys.now() + base_t + 86400*3
    return sys.now() + base_t
end

function M.walltime()
    if not midnight then
        return 0, 0
    else
        local time = (midnight + sys.now()) % 86400
        return math.floor(time/3600), math.floor(time % 3600 / 60)
    end
end

function M.walltime_text()
    local h, m = M.walltime()
    return string.format("%02d:%02d", h, m)
end

util.data_mapper{
    ["clock/unix"] = function(time)
        logger:debug("new time: ", time)
        base_t = tonumber(time) - sys.now()
    end;
    ["clock/midnight"] = function(since_midnight)
        logger:debug("new midnight: ", since_midnight)
        midnight = tonumber(since_midnight) - sys.now()
    end;
}

return M
