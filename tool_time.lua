function Time()
    local base_t = os.time() - sys.now()
    local midnight

    local function unixtime()
        -- return sys.now() + base_t + 86400*3
        return sys.now() + base_t
    end

    local function walltime()
        if not midnight then
            return 0, 0
        else
            local time = (midnight + sys.now()) % 86400
            return math.floor(time/3600), math.floor(time % 3600 / 60)
        end
    end

    util.data_mapper{
        ["clock/unix"] = function(time)
            -- print("new time: ", time)
            base_t = tonumber(time) - sys.now()
        end;
        ["clock/midnight"] = function(since_midnight)
            -- print("new midnight: ", since_midnight)
            midnight = tonumber(since_midnight) - sys.now()
        end;
    }

    return {
        unixtime = unixtime;
        walltime = walltime;
    }
end

return Time()
