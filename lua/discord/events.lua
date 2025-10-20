-- Event handling and autocmds
local M = {}

local uv = vim.loop
local timer = nil
---@class State
---@field mode string
---@field start_at number
---@field config table
local state_ref = nil

local function update_mode(mode)
  if state_ref.mode ~= mode then
    state_ref.mode = mode
    state_ref.start_at = os.time()
  end
  require("discord.activity").update()
end

local function schedule_idle()
  if not timer then timer = uv.new_timer() end
  timer:stop()
  timer:start(state_ref.config.idle_timeout_ms, 0, function()
    vim.schedule(function()
      update_mode("idle")
    end)
  end)
end

local function cancel_idle()
  if timer then timer:stop() end
end

function M.setup(state)
  state_ref = state
  
  local aug = vim.api.nvim_create_augroup("discord_nvim", { clear = true })
  
  vim.api.nvim_create_autocmd({"BufEnter", "WinEnter"}, {
    group = aug,
    callback = function()
      cancel_idle()
      update_mode("viewing")
    end,
  })
  
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = aug,
    callback = function()
      cancel_idle()
      update_mode("editing")
    end,
  })
  
  vim.api.nvim_create_autocmd({"InsertLeave", "CursorHold", "CursorHoldI"}, {
    group = aug,
    callback = schedule_idle,
  })
  
  vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
    group = aug,
    callback = function()
      cancel_idle()
      require("discord.activity").update()
    end,
  })
  
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
      require("discord").shutdown()
    end,
  })
  
  vim.schedule(function()
    update_mode("viewing")
  end)
end

return M
