local M = {}

local uv = vim.loop
local binary = require("presence.utils.downloader")
local connection = require("presence.core.connection")
local state = require("presence.state")

local proc = nil

function M.start_daemon()
  local bin_path = binary.get_binary_path()
  proc = uv.spawn(bin_path, { 
    args = {}, 
    cwd = vim.fn.getcwd() 
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
  
  -- Ensure binary exists
  if not binary.ensure_binary_exists() then
    -- Wait a bit for download to complete, then try again
    uv.new_timer():start(2000, 0, function()
      M.ensure_started(config, on_ready)
    end)
    return
  end
  
  local addr = "/tmp/presenced.sock"
  
  connection.connect(addr, function(success, err)
    if success then
      -- Connected successfully
      connection.write_json({ 
        action = "init", 
        payload = { 
          client_id = config.client_id, 
          session_id = state.get_session_id() 
        } 
      })
      if on_ready then on_ready(true) end
    else
      -- Connection failed, try to start daemon
      if M.start_daemon() then
        -- Retry connection after short delay
        uv.new_timer():start(200, 0, function()
          connection.connect(addr, function(success2, err2)
            if success2 then
              connection.write_json({ 
                action = "init", 
                payload = { 
                  client_id = config.client_id, 
                  session_id = state.get_session_id() 
                } 
              })
              if on_ready then on_ready(true) end
            else
              vim.schedule(function()
                vim.notify("discord.nvim: failed to connect to daemon: " .. (err2 or "unknown error"), vim.log.levels.ERROR)
              end)
              if on_ready then on_ready(false, err2) end
            end
          end)
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

function M.shutdown()
  -- Just close the connection - the daemon will auto-shutdown when no clients remain
  connection.close()
  -- Don't kill the daemon process - let it handle its own lifecycle
end

return M
