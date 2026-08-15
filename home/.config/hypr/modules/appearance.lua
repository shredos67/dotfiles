--[[
this file draws gaps borders shadows blur and floral edges
pywal supplies every color used here
]]

return function(context)
    local wal = context.wal

    hl.config({
        general = {
            gaps_in = 20,
            gaps_out = 25,
            border_size = 3,
            col = {
                active_border = {
                    colors = {
                        wal.rgba("color4", "f0"),
                        wal.rgba("color5", "dc"),
                        wal.rgba("color6", "c8"),
                    },
                    angle = 45,
                },
                inactive_border = wal.rgba("color4", "60"),
            },
            resize_on_border = true,
            allow_tearing = false,
            layout = "dwindle",
        },

        decoration = {
            rounding = context.border_rounding(
                context.border_plus_plus_size),
            rounding_power = 2.4,
            active_opacity = 1.0,
            inactive_opacity = 0.96,
            fullscreen_opacity = 1.0,
            dim_modal = true,
            dim_inactive = false,
            dim_strength = 0.0,
            dim_special = 0.24,
            dim_around = 0.62,

            shadow = {
                enabled = false,
                range = 8,
                render_power = 2,
                sharp = false,
                color = wal.rgba("background", "c8"),
                color_inactive = wal.rgba("background", "88"),
                offset = { 0, 3 },
                scale = 0.98,
            },

            glow = {
                enabled = false,
                range = 4,
                render_power = 3,
                color = wal.rgba("color4", "24"),
                color_inactive = wal.rgba("color4", "0d"),
            },

            blur = {
                enabled = false,
                size = 4,
                passes = 1,
                new_optimizations = true,
                noise = 0.008,
                contrast = 0.94,
                brightness = 0.92,
                vibrancy = 0.12,
                vibrancy_darkness = 0.08,
                popups = true,
                popups_ignorealpha = 0.72,
            },
        },

        plugin = {
            borders_plus_plus = {
                add_borders = 1,
                natural_rounding = false,
                border_size_1 = context.border_plus_plus_size,
                col = {
                    border_1 = wal.rgba("background", "ee"),
                },
            },
        },

        animations = {
            enabled = true,
        },
    })

    if context.plugin_loaded("imgborders") then
        hl.config({
            plugin = {
                imgborders = {
                    image = context.home
                        .. "/.config/hypr/assets/imgborders-floral.png",
                    sizes = 600,
                    insets = 665,
                    scale = 0.12,
                    smooth = true,
                    blur = false,
                },
            },
        })
    end

    hl.layer_rule({
        name = "shell-depth",
        match = { namespace = "quickshell" },
        blur = true,
        blur_popups = true,
        ignore_alpha = 0.72,
    })

    hl.layer_rule({
        name = "menu-depth",
        match = { namespace = "caelestia-menus" },
        blur = true,
        blur_popups = true,
        ignore_alpha = 0.72,
    })
end
