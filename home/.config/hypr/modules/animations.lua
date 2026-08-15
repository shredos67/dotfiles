--[[
this file keeps every desktop motion on cubic curves
there are no spring or bounce animations here
]]

return function()
    hl.curve("easeOutCubic", {
        type = "bezier",
        points = { { 0.215, 0.61 }, { 0.355, 1 } },
    })
    hl.curve("easeInCubic", {
        type = "bezier",
        points = { { 0.55, 0.055 }, { 0.675, 0.19 } },
    })
    hl.curve("easeInOutCubic", {
        type = "bezier",
        points = { { 0.645, 0.045 }, { 0.355, 1 } },
    })
    hl.curve("easeOutQuart", {
        type = "bezier",
        points = { { 0.165, 0.84 }, { 0.44, 1 } },
    })
    hl.curve("linear", {
        type = "bezier",
        points = { { 0, 0 }, { 1, 1 } },
    })

    hl.animation({
        leaf = "global", enabled = true, speed = 6,
        bezier = "easeInOutCubic",
    })
    hl.animation({
        leaf = "border", enabled = true, speed = 4.2,
        bezier = "easeOutCubic",
    })
    hl.animation({
        leaf = "windows", enabled = true, speed = 4.6,
        bezier = "easeInOutCubic",
    })
    hl.animation({
        leaf = "windowsIn", enabled = true, speed = 4.7,
        bezier = "easeOutCubic", style = "popin 94%",
    })
    hl.animation({
        leaf = "windowsOut", enabled = true, speed = 3.1,
        bezier = "easeInCubic", style = "popin 94%",
    })
    hl.animation({
        leaf = "windowsMove", enabled = true, speed = 4.2,
        bezier = "easeInOutCubic",
    })
    hl.animation({
        leaf = "fadeIn", enabled = true, speed = 3.1,
        bezier = "easeOutCubic",
    })
    hl.animation({
        leaf = "fadeOut", enabled = true, speed = 2.7,
        bezier = "easeInCubic",
    })
    hl.animation({
        leaf = "fade", enabled = true, speed = 3.4,
        bezier = "easeInOutCubic",
    })
    hl.animation({
        leaf = "layers", enabled = true, speed = 4.0,
        bezier = "easeInOutCubic",
    })
    hl.animation({
        leaf = "layersIn", enabled = true, speed = 4.2,
        bezier = "easeOutCubic", style = "fade",
    })
    hl.animation({
        leaf = "layersOut", enabled = true, speed = 2.9,
        bezier = "easeInCubic", style = "fade",
    })
    hl.animation({
        leaf = "fadeLayersIn", enabled = true, speed = 3.2,
        bezier = "easeOutCubic",
    })
    hl.animation({
        leaf = "fadeLayersOut", enabled = true, speed = 2.7,
        bezier = "easeInCubic",
    })
    hl.animation({
        leaf = "workspaces", enabled = true, speed = 4.0,
        bezier = "easeInOutCubic", style = "slide",
    })
    hl.animation({
        leaf = "workspacesIn", enabled = true, speed = 3.8,
        bezier = "easeOutCubic", style = "slide",
    })
    hl.animation({
        leaf = "workspacesOut", enabled = true, speed = 3.4,
        bezier = "easeInCubic", style = "slide",
    })
    hl.animation({
        leaf = "specialWorkspace", enabled = true, speed = 4.2,
        bezier = "easeOutQuart", style = "slidevert",
    })
    hl.animation({
        leaf = "zoomFactor", enabled = true, speed = 6,
        bezier = "easeOutCubic",
    })
end
