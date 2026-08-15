--[[
this file holds keyboard mouse touchpad and gesture settings
keep device specific changes out of the other modules
]]

return function()
    hl.config({
        input = {
            kb_layout = "se",
            kb_variant = "",
            kb_model = "",
            kb_options = "",
            kb_rules = "",
            follow_mouse = 1,
            accel_profile = "adaptive",
            force_no_accel = false,
            sensitivity = 0.0,
            touchpad = {
                natural_scroll = true,
            },
        },
    })

    hl.gesture({
        fingers = 3,
        direction = "horizontal",
        action = "workspace",
    })

    hl.device({
        name = "epic-mouse-v1",
        sensitivity = -0.5,
    })
end
