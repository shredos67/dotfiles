--[[
this file controls tiling workspaces and desktop defaults
the first four workspaces stay available for the shell
]]

return function()
    hl.config({
        dwindle = {
            preserve_split = true,
            smart_resizing = true,
            precise_mouse_move = true,
            special_scale_factor = 0.94,
        },
        master = {
            new_status = "master",
        },
        scrolling = {
            fullscreen_on_one_column = true,
        },
        misc = {
            force_default_wallpaper = 0,
            disable_hyprland_logo = true,
            focus_on_activate = true,
        },
    })

    for workspace = 1, 4 do
        hl.workspace_rule({
            workspace = tostring(workspace),
            persistent = true,
        })
    end
end
