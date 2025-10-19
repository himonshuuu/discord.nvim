local M = {}

local uv = vim.loop
local binary = require("presence.utils.downloader")
local connection = require("presence.core.connection")
local state = require("presence.state")

local proc = nil

function M.start_daemon()
  local bin_path = binary.get_binary_path()
  proc = uv.spawn(bin_path, { 
    args = {}
  }, function()
    proc = nil
  end)
  return proc ~= nil
end

function M.is_running()
  return proc ~= nil
end

function M.stop_daemon()
  if proc then
    proc:kill("TERM")
    proc = nil
  end
end

function M.ensure_started(config, on_ready)
  if proc then 
    if on_ready then on_ready(true) end
    return 
  end
  
  if not binary.ensure_binary_exists() then
    uv.new_timer():start(2000, 0, function()
      M.ensure_started(config, on_ready)
    end)
    return
  end
  
  local addr = "/tmp/presenced.sock"
  
  connection.connect(addr, function(success, err)
    if success then
      connection.write_json({ 
        action = "init", 
        payload = { 
          client_id = config.client_id, 
          session_id = state.get_session_id() 
        } 
      })
      if on_ready then on_ready(true) end
    else
      if M.start_daemon() then
        uv.new_timer():start(1000, 0, function()
          M.retry_connection_with_backoff(addr, config, on_ready, 0)
        end)
      else
        vim.schedule(function()
          vim.notify("discord.nvim: failed to start daemon", vim.log.levels.ERROR)
        end)
        if on_ready then on_ready(false, "Failed to start daemon") end
      end
    end
  end)
end

function M.retry_connection_with_backoff(addr, config, on_ready, attempt)
  local max_attempts = 5
  local delays = { 500, 1000, 2000, 3000, 5000 }
  
  if attempt >= max_attempts then
    vim.schedule(function()
      vim.notify("discord.nvim: failed to connect to daemon after " .. max_attempts .. " attempts", vim.log.levels.ERROR)
    end)
    if on_ready then on_ready(false, "Connection timeout") end
    return
  end
  
  connection.connect(addr, function(success, err)
    if success then
      connection.write_json({ 
        action = "init", 
        payload = { 
          client_id = config.client_id, 
          session_id = state.get_session_id() 
        } 
      })
      if on_ready then on_ready(true) end
    else
      local delay = delays[attempt + 1] or delays[#delays]
      uv.new_timer():start(delay, 0, function()
        M.retry_connection_with_backoff(addr, config, on_ready, attempt + 1)
      end)
    end
  end)
end

function M.shutdown()
  connection.close()

  if proc then
    proc:kill("TERM")
    proc = nil
  end
  
  local addr = "/tmp/presenced.sock"
  uv.fs_unlink(addr, function() end) 
end

return M
