local M = {}

local cache_home = vim.env.XDG_CACHE_HOME
if not cache_home or cache_home == "" then
  cache_home = vim.fn.expand "~/.cache"
end

local function read_palette()
  local file = io.open(cache_home .. "/wal/colors.json", "r")
  if not file then
    return nil
  end

  local contents = file:read "*a"
  file:close()

  local ok, palette = pcall(vim.json.decode, contents)
  if not ok or type(palette) ~= "table" or type(palette.colors) ~= "table" then
    return nil
  end

  return palette
end

local function rgb(hex)
  hex = (hex or "#000000"):gsub("#", "")
  return tonumber(hex:sub(1, 2), 16) or 0,
    tonumber(hex:sub(3, 4), 16) or 0,
    tonumber(hex:sub(5, 6), 16) or 0
end

local function mix(first, second, amount)
  local ar, ag, ab = rgb(first)
  local br, bg, bb = rgb(second)
  local function channel(a, b)
    return math.floor(a + (b - a) * amount + 0.5)
  end

  return string.format("#%02X%02X%02X", channel(ar, br), channel(ag, bg), channel(ab, bb))
end

local palette = read_palette()
if not palette then
  return require "base46.themes.onedark"
end

local colors = palette.colors
local background = palette.special.background
local foreground = palette.special.foreground

M.base_30 = {
  white = foreground,
  darker_black = mix(background, "#000000", 0.16),
  black = background,
  black2 = mix(background, foreground, 0.07),
  one_bg = mix(background, foreground, 0.11),
  one_bg2 = mix(background, foreground, 0.16),
  one_bg3 = mix(background, foreground, 0.22),
  grey = mix(background, foreground, 0.30),
  grey_fg = colors.color8,
  grey_fg2 = mix(colors.color8, foreground, 0.30),
  light_grey = mix(colors.color8, foreground, 0.48),
  red = colors.color1,
  baby_pink = mix(colors.color1, colors.color5, 0.48),
  pink = colors.color5,
  line = mix(background, foreground, 0.14),
  green = colors.color2,
  vibrant_green = colors.color10,
  nord_blue = colors.color12,
  blue = colors.color4,
  yellow = colors.color3,
  sun = colors.color11,
  purple = colors.color5,
  dark_purple = colors.color13,
  teal = colors.color6,
  orange = mix(colors.color1, colors.color3, 0.58),
  cyan = colors.color6,
  statusline_bg = mix(background, foreground, 0.08),
  lightbg = mix(background, foreground, 0.18),
  pmenu_bg = colors.color4,
  folder_bg = colors.color4,
}

M.base_16 = {
  base00 = background,
  base01 = mix(background, foreground, 0.08),
  base02 = mix(background, foreground, 0.15),
  base03 = colors.color8,
  base04 = mix(colors.color8, foreground, 0.45),
  base05 = foreground,
  base06 = mix(foreground, "#FFFFFF", 0.16),
  base07 = mix(foreground, "#FFFFFF", 0.28),
  base08 = colors.color1,
  base09 = colors.color3,
  base0A = colors.color6,
  base0B = colors.color2,
  base0C = colors.color14,
  base0D = colors.color4,
  base0E = colors.color5,
  base0F = colors.color9,
}

M.type = "dark"
M = require("base46").override_theme(M, "pywal")

return M
