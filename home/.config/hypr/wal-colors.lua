local colors = {
    background = "#18191f",
    foreground = "#c5c5c7",
    color0 = "#18191f",
    color1 = "#C8A175",
    color2 = "#6C5B8C",
    color3 = "#664E98",
    color4 = "#996C9A",
    color5 = "#C279B1",
    color6 = "#D3A99C",
    color7 = "#c5c5c7",
    color8 = "#5f6475",
    color9 = "#C8A175",
    color10 = "#6C5B8C",
    color11 = "#664E98",
    color12 = "#996C9A",
    color13 = "#C279B1",
    color14 = "#D3A99C",
    color15 = "#c5c5c7",
}

function colors.rgba(name, alpha)
    local hex = colors[name]:gsub("^#", "")
    return "rgba(" .. hex .. (alpha or "ff") .. ")"
end

return colors
