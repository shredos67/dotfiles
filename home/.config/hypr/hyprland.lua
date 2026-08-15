--[[
this file only loads the hyprland modules
edit one module at a time and verify before reloading
]]

local context = require("modules.context")

require("modules.environment")(context)
require("modules.appearance")(context)
require("modules.animations")(context)
require("modules.layouts")(context)
require("modules.input")(context)
require("modules.bindings")(context)
require("modules.rules")(context)
