--[[
this file keeps app behavior separate from the visual config
specific tools float without changing normal app placement
]]

return function()
    hl.window_rule({
        name = "suppress-maximize-events",
        match = { class = ".*" },
        suppress_event = "maximize",
    })

    hl.window_rule({
        name = "fix-xwayland-drags",
        match = {
            class = "^$",
            title = "^$",
            xwayland = true,
            float = true,
            fullscreen = false,
            pin = false,
        },
        no_focus = true,
    })

    hl.window_rule({
        name = "background-obs-recorder",
        match = { class = "(obs|com.obsproject.Studio)" },
        workspace = "special:obs-recorder silent",
        no_initial_focus = true,
        no_anim = true,
    })

    hl.window_rule({
        name = "move-hyprland-run",
        match = { class = "hyprland-run" },
        move = "20 monitor_h-120",
        float = true,
    })

    hl.window_rule({
        name = "float-system-tools",
        match = {
            class = "(blueman-manager|nm-connection-editor|pavucontrol|nwg-look|qt5ct|qt6ct)",
        },
        float = true,
        center = true,
        dim_around = true,
    })

    hl.window_rule({
        name = "float-picture-in-picture",
        match = { title = "(Picture-in-Picture|Picture in picture)" },
        float = true,
        pin = true,
        keep_aspect_ratio = true,
    })
end
