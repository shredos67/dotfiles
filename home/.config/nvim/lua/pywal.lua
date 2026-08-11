--[[
this file follows pywal inside neovim
it reloads when the theme file changes
keep the generated palette out of git
]]

local M = {}

local cache_home = vim.env.XDG_CACHE_HOME
if not cache_home or cache_home == "" then
  cache_home = vim.fn.expand "~/.cache"
end

local wal_dir = cache_home .. "/wal"
local wal_file = wal_dir .. "/colors.json"
local watcher
local debounce
local last_stamp

local function file_stamp()
  local stat = vim.uv.fs_stat(wal_file)
  if not stat then
    return nil
  end

  return table.concat({ stat.size, stat.mtime.sec, stat.mtime.nsec }, ":")
end

function M.reload()
  package.loaded["themes.pywal"] = nil

  local ok, err = pcall(function()
    require("base46").load_all_highlights()
    vim.g.colors_name = "pywal"
    vim.cmd.redraw()
  end)

  if not ok then
    vim.schedule(function()
      vim.notify("Could not reload Pywal theme: " .. tostring(err), vim.log.levels.ERROR)
    end)
  end
end

local function reload_if_changed()
  local stamp = file_stamp()
  if not stamp or stamp == last_stamp then
    return
  end

  last_stamp = stamp
  M.reload()
end

local function queue_reload()
  if not debounce then
    return
  end

  debounce:stop()
  debounce:start(80, 0, vim.schedule_wrap(reload_if_changed))
end

function M.setup()
  if watcher then
    return
  end

  vim.g.colors_name = "pywal"
  last_stamp = file_stamp()
  debounce = vim.uv.new_timer()
  watcher = vim.uv.new_fs_event()

  if watcher then
    watcher:start(wal_dir, {}, function(error, filename)
      if error then
        return
      end

      if not filename or filename == "colors.json" then
        queue_reload()
      end
    end)
  end

  local group = vim.api.nvim_create_augroup("PywalLiveTheme", { clear = true })
  vim.api.nvim_create_autocmd({ "FocusGained", "TermLeave" }, {
    group = group,
    callback = reload_if_changed,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if watcher and not watcher:is_closing() then
        watcher:stop()
        watcher:close()
      end
      if debounce and not debounce:is_closing() then
        debounce:stop()
        debounce:close()
      end
    end,
  })

  vim.api.nvim_create_user_command("PywalReload", M.reload, {
    desc = "Reload NvChad highlights from the current Pywal palette",
  })
end

return M
