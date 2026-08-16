--[[
this file holds every keyboard and mouse action
shell shortcuts use quickshell ipc so only one panel owns state
]]

return function(context)
    local main = "SUPER"

    hl.bind(main .. " + T", hl.dsp.exec_cmd(context.terminal))
    hl.bind(main .. " + Q", hl.dsp.window.close())
    hl.bind(main .. " + SPACE",
        hl.dsp.exec_cmd("qs ipc call launcher toggle"))
    hl.bind(main .. " + D",
        hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
    hl.bind(main .. " + F",
        hl.dsp.window.fullscreen("fullscreen", "toggle"))
    hl.bind(main .. " + M",
        hl.dsp.exec_cmd("qs ipc call powerMenu toggle"))
    hl.bind(main .. " + W",
        hl.dsp.exec_cmd("qs ipc call wallpaperCarousel toggle"))
    hl.bind(main .. " + N",
        hl.dsp.exec_cmd("qs ipc call notificationPanel toggle"))
    hl.bind(main .. " + comma",
        hl.dsp.exec_cmd("qs ipc call settings toggle"))
    hl.bind(main .. " + A",
        hl.dsp.exec_cmd("qs ipc call dashboard toggle"))
    hl.bind(main .. " + L", hl.dsp.exec_cmd("hyprlock"))
    hl.bind(main .. " + E", hl.dsp.exec_cmd(context.file_manager))
    hl.bind(main .. " + V", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(main .. " + R", hl.dsp.exec_cmd(context.menu))
    hl.bind(main .. " + P", hl.dsp.window.pseudo())
    hl.bind(main .. " + J", hl.dsp.layout("togglesplit"))

    hl.bind(main .. " + left", hl.dsp.focus({ direction = "left" }))
    hl.bind(main .. " + right", hl.dsp.focus({ direction = "right" }))
    hl.bind(main .. " + up", hl.dsp.focus({ direction = "up" }))
    hl.bind(main .. " + down", hl.dsp.focus({ direction = "down" }))

    for workspace = 1, 10 do
        local key = workspace % 10
        hl.bind(main .. " + " .. key,
            hl.dsp.focus({ workspace = workspace }))
        hl.bind(main .. " + SHIFT + " .. key,
            hl.dsp.window.move({ workspace = workspace }))
    end

    hl.bind(main .. " + S", hl.dsp.workspace.toggle_special("magic"))
    hl.bind(main .. " + SHIFT + S",
        hl.dsp.window.move({ workspace = "special:magic" }))
    hl.bind(main .. " + mouse_down",
        hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(main .. " + mouse_up",
        hl.dsp.focus({ workspace = "e-1" }))
    hl.bind(main .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind(main .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    hl.bind("XF86AudioRaiseVolume",
        hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
        { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume",
        hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
        { locked = true, repeating = true })
    hl.bind("XF86AudioMute",
        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
        { locked = true, repeating = true })
    hl.bind("XF86AudioMicMute",
        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
        { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessUp",
        hl.dsp.global("caelestia:barBrightnessUp"),
        { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown",
        hl.dsp.global("caelestia:barBrightnessDown"),
        { locked = true, repeating = true })

    hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),
        { locked = true })
    hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"),
        { locked = true })
    hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"),
        { locked = true })
    hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"),
        { locked = true })
end
