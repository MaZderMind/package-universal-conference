local json = require "json"

local change_listeners = {}
local prev_config = nil

-- you can register a change-listener for multiple options
-- if more then one option of this list changes at the same time,
-- your listener will only be called once
local function on_option_changed(options, callback)
    local options = options
    if type(options) == 'string' then
        options = {options}
    end

    for _, option in ipairs(options) do
        if type(change_listeners[option]) == 'nil' then
            change_listeners[option] = {}
        end

        table.insert(change_listeners[option], callback)
    end
end

local function diff_config(old, new, stack)
    local stack = stack or {}

    local changes = {}
    for k, v in pairs(old) do
        table.insert(stack, k)
        local index = table.concat(stack, '.')

        if type(old[k]) ~= type(new[k]) then
            -- print("type changes", index)
            table.insert(changes, index)
        else
            if type(old[k]) == 'table' then
                -- print("recurse", index)
                local recurse_changes = diff_config(old[k], new[k], stack)
                for idx, recurse_change in ipairs(recurse_changes) do
                    table.insert(changes, recurse_change)
                end
            else
                if old[k] ~= new[k] then
                    -- print("literal changes", index)
                    table.insert(changes, index)
                end
            end
        end
        table.remove(stack)
    end

    for k, v in pairs(new) do
        table.insert(stack, k)
        local index = table.concat(stack, '.')

        -- detect new
        if type(old[k]) ~= type(new[k]) then
            table.insert(changes, index)
        end

        table.remove(stack)
    end

    return changes
end

util.file_watch("config.json", function(raw)
    local config = json.decode(raw)
    if type(prev_config) == 'nil' then
        print("initial")
        prev_config = config
        return
    end

    print("changed")
    local changes = diff_config(prev_config, config)
    pp(changes)
    prev_config = config

    local callbacks_done = {}
    for _, change in ipairs(changes) do
        local pieces = {}
        for piece in string.gmatch(change, "[^%.]+") do
            table.insert(pieces, piece)
        end
        while #pieces > 0 do
            local option = table.concat(pieces, ".")
            if type(change_listeners[option]) ~= 'nil' then
                for _, callback in ipairs(change_listeners[option]) do
                    if not callbacks_done[callback] then
                        callbacks_done[callback] = true
                        pcall(callback)
                    end
                end
            end

            table.remove(pieces)
        end
    end
end)

return {
    on_option_changed = on_option_changed;
}
