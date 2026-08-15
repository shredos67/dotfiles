--[[
this file holds shared hyprland values
keep paths and border sizes together here
]]

local context = {}

context.home = os.getenv("HOME") or "/home/shredos"
context.wal = require("wal-colors")
context.terminal = "foot"
context.file_manager = "nautilus"
context.menu = "qs --path " .. context.home
    .. "/.config/quickshell/zen --no-duplicate"

context.border_plus_plus_size = 8
context.outer_border_rounding = 18

function context.border_rounding(inset)
    return math.max(0, context.outer_border_rounding - (inset or 0))
end

function context.plugin_loaded(name)
    for _, plugin in pairs(hl.get_loaded_plugins()) do
        if plugin.name == name then
            return true
        end
    end
    return false
end

return context
