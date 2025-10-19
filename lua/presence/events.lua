local M = {}

local uv = vim.loop
local state = require("presence.state")
local daemon = require("presence.daemon")

local idle_timer = nil

local function ensure_timer()
  if not idle_timer then
    idle_timer = uv.new_timer()
  end
  return idle_timer
end

function M.update_presence(mode)
  state.set_mode(mode)
  daemon.push_activity(mode)
end

function M.refresh_presence()
  daemon.push_activity(state.get_mode())
end

local function schedule_idle()
  local cfg = state.get_config()
  local t = ensure_timer()
  t:stop()
  t:start(cfg.idle_timeout_ms, 0, function()
    vim.schedule(function()
      M.update_presence("idle")
    end)
  end)
end

function M.register_autocmds()
  local aug = vim.api.nvim_create_augroup("presence_nvim", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = aug,
    callback = function()
      schedule_idle()
      M.update_presence("viewing")
    end,
  })
  vim.api.nvim_create_autocmd({ "InsertEnter" }, {
    group = aug,
    callback = function()
      schedule_idle()
      M.update_presence("editing")
    end,
  })
  vim.api.nvim_create_autocmd({ "InsertLeave", "CursorHold", "CursorHoldI" }, {
    group = aug,
    callback = function()
      schedule_idle()
    end,
  })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = aug,
    callback = function()
      schedule_idle()
      M.refresh_presence()
    end,
  })
  vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
    group = aug,
    callback = function()
      require("presence").shutdown()
    end,
  })
end

return M


