function Fadeout()
    local current_alpha = 1
    local fade_til = 0

    local function alpha()
        return current_alpha
    end

    local function fade(t)
        fade_til = sys.now() + t
    end

    local function tick()
        local target_alpha = sys.now() > fade_til and 1 or 0

        if current_alpha < target_alpha then
            current_alpha = current_alpha + 0.01
        elseif current_alpha > target_alpha then
            current_alpha = current_alpha - 0.01
        end
    end

    return {
        alpha = alpha;
        tick = tick;
        fade = fade;
    }
end

return Fadeout
