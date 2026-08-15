--[[
this file starts the session and exports app variables
keep login commands light so the desktop appears cleanly
]]

return function(context)
    hl.monitor({
        output = "",
        mode = "preferred",
        position = "auto",
        scale = "1.33",
    })

    hl.permission("/usr/bin/hyprpm", "plugin", "allow")

    hl.on("hyprland.start", function()
        hl.exec_cmd("systemctl --user start hyprland-session.target")
        hl.exec_cmd("hyprlock")
        hl.exec_cmd("qs --path " .. context.home
            .. "/.config/quickshell --daemonize")
        hl.exec_cmd("awww-daemon")
        hl.exec_cmd(context.home
            .. "/wallpaperCarousel/restore-wallpaper.sh")
        hl.exec_cmd(context.home
            .. "/.local/bin/reload-hypr-plugins-layered")
    end)

    hl.on("hyprland.shutdown", function()
        os.execute("systemctl --user stop hyprland-session.target")
    end)

    hl.env("XCURSOR_SIZE", "24")
    hl.env("HYPRCURSOR_SIZE", "24")
    hl.env("QML2_IMPORT_PATH", context.home .. "/.config/quickshell")
    hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
    hl.env("QT_QPA_PLATFORMTHEME_QT6", "qt6ct")
end
